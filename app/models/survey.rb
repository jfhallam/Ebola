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
	if current_question == Survey.questions.count
		complete_survey
	else
		send_question(current_question)	
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

def	complete_survey
	self.update_attribute(:completed_at, Time.now)
	true_answers = 0
	Survey.questions.each_with_index do |q,i|
		true_answers += 1 if self.send("q#{i}")
	end
	self.update_attribute(:score, true_answers)
	send_results
end

def send_results
	if self.score < 5
		Twilio::SMS.create :to => self.number, :from => '+17209032094', :body => "Survey complete. You scored a #{self.score}, don't sweat it."
	else
		Twilio::SMS.create :to => self.number, :from => '+17209032094', :body => "Survey complete. Oh shit! You scored a #{self.score}, good luck with that."
	end	
end

def self.create_multiple(params)
	params[:multi].split(10.chr).each do |line|
		Survey.create(:number => line.split(",")[0], :name => line.split(",")[1])
	end
end

end



