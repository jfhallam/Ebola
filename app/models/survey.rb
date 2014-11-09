class Survey < ActiveRecord::Base
attr_accessor :params, :multi
before_save :set_parsed_number

def set_parsed_number
	self.parsed_number = self.number.to_s.tr('^0-9', '').reverse[0...10].reverse
end

def self.questions
	["Do you live in a high risk area?",
   "Do you know someone who has been to the hospital for fever?",
	 "Do you live with someone who has fallen ill in the last 21 days?",
   "Have you touched someone who is sick?",
   "Have you touched a dead body?",
   "Have you performed burial rights?",
   "Have you been exposed to blood, vomit, feces, mucus?",
   "Do you have a fever? (higher than normal body temperature) do you feel hotter than normal?",
   "Have you vomited, had diahhrea or unexplained bruising or bleeding in the last 21 days?",
   "Have you had a severe headache, muscle pain, fatigue, or stomach pains in the last 21 days?"]
end

after_create :launch_survey

def launch_survey
	Twilio::SMS.create :to => self.number, :from => '+17209032094', :body => 'The Ebola Response Team would like to ask you a couple questions about your risk factors for ebola.'	
	ask_question
end

def self.incoming(params)
		logger.debug "incoming"
		if s = Survey.where(:parsed_number => params["From"].to_s.reverse[0...10].reverse).first
			logger.debug "Found #{s.id}"
			s.params = params
			if s.completed_at? 
				s.send_results
			else
				s.save_answer
				s.reload
				s.ask_question
			end
    else
			logger.debug "launch survey"
    	# No record
    	s.launch_survey
    end
end

def ask_question
	logger.debug "--------#{current_question}:#{Survey.questions.count}"
	if self.ready_to_complete?
		complete_survey
	else
		send_question(current_question)	
	end
end

def ready_to_complete?
	if current_question == 3
		if self.no_risk?
			return true
		else
			return false
		end
	elsif current_question == Survey.questions.count
		return true
	else
		return false
	end
end

def send_question(i)
		logger.debug("send question #{i}: #{Survey.questions[i]}")
		Twilio::SMS.create :to => self.number, :from => '+17209032094', :body => Survey.questions[i] + " Text 1 for YES, 2 for NO."
end

def take_next_step
	if self.completed_at?
		logger.debug "tns:1"
		Twilio::SMS.create :to => self.number, :from => '+17209032094', :body => 'We received your survey on #{self.completed_at.to_s}.'	
	else
		logger.debug "tns:2"
		if save_answer
			logger.debug "tns:3"
			ask_next_question
		else
			ask_question_again
		end
	end
end

def current_question
	Survey.questions.each_with_index do |q,i|
		return i if self.send("q#{i}") == nil
	end
	Survey.questions.count
end

def save_answer
	if params["Body"] == "1" || params["Body"].downcase == "y" || params["Body"].downcase == "yes"
		update_attribute("q#{current_question}", true)
		return true
	elsif params["Body"] == "2" || params["Body"].downcase == "n" || params["Body"].downcase == "no"
		update_attribute("q#{current_question}", false)
		return true
	end
end

def no_risk?
	self.q0 == false && self.q1 == false && self.q2 == false
end

def	complete_survey
	calculate_scores

	if risk_score.between?(0,1)
		self.exposure_risk = "Unlikely"
		if score.between?(0,4)
			self.risk_level = "Very Low"
		elsif score.between?(5,7)
			self.risk_level = "Low"
		end			
	elsif risk_score.between?(2,2)
		self.exposure_risk = "Unlikely Direct"
		if score.between?(0,0)
			self.risk_level = "Very Low"
		elsif score.between?(1,14)
			self.risk_level = "Low"
		end					
	elsif risk_score.between?(3,4)
		self.exposure_risk = "Likely Direct"	
		if symptom_score.between?(0,4)
			self.risk_level = "Medium"
		elsif symptom_score.between?(5,7)
			self.risk_level = "Extreme"
		end			
	elsif risk_score.between?(7,21)
		self.exposure_risk = "Direct"	
		if symptom_score.between?(0,4)
			self.risk_level = "High"
		elsif symptom_score.between?(5,7)
			self.risk_level = "Extreme"
		end			
	end

	self.completed_at = Time.now
	self.save

#	if survey.no_risk?
#		self.risk_level = "Very Low"
#		Twilio::SMS.create :to => self.number, :from => '+17209032094', :body => "Survey complete. You are at VERY LOW risk. Avoid sick people and drink purified water."
#	end	

#	true_answers = 0
#	Survey.questions.each_with_index do |q,i|
#		true_answers += 1 if self.send("q#{i}")
#	end
#	self.update_attribute(:score, true_answers)
	send_results
end

def send_results
	if self.risk_level == "Very Low"
		msg = "Avoid sick people, drink purified water. Learn to purify water..."
	elsif self.risk_level == "Low"
		msg = "Wash hands, avoid sick people, drink clean water. Find a Doctor near you..."
	elsif self.risk_level == "Medium"
		msg = "avoid contact with others. Find a Doctor Near You..."
	elsif self.risk_level == "High"
		msg = "Isolate yourself from others - We have notified the CDC.  Learn more..."
	elsif self.risk_level == "Extreme"
		msg = "Isolate yourself, we have notified CDC. Learn More..."
	end

	Twilio::SMS.create :to => self.number, :from => '+17209032094', :body => "Survey complete. Your risk level is #{self.risk_level.upcase}. #{msg}"
	Twilio::SMS.create :to => self.number, :from => '+17209032094', :body => "Ebola Tips: 1) Wash hands with soap and clean wate, 2) Avoid physical contact with others."
end

def self.create_multiple(params)
	params[:multi].split(10.chr).each do |line|
		Survey.create(:number => line.split(",")[0], :name => line.split(",")[1])
	end
end

def calculate_scores
	self.risk_score = 0
	self.risk_score += 1 if q0 == true
	self.risk_score += 1 if q1 == true
	self.risk_score += 2 if q2 == true
	self.risk_score += 3 if q3 == true
	self.risk_score += 4 if q4 == true
	self.risk_score += 5 if q5 == true
	self.risk_score += 6 if q6 == true

	self.symptom_score = 0
	self.symptom_score += 2 if q7 == true
	self.symptom_score += 2 if q8 == true
	self.symptom_score += 3 if q9 == true

	self.score = risk_score * symptom_score
	true
end

end



