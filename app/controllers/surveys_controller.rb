class SurveysController < ApplicationController
  before_action :set_survey, only: [:show, :edit, :update, :destroy]
  skip_before_filter  :verify_authenticity_token

  def twilio
    Survey.incoming(params)
    render :text => params.inspect
  end


# {"ToCountry"=>"US", "ToState"=>"CO", "SmsMessageSid"=>"SMee75840411b997aa68ed3e6fa55be0ed", "NumMedia"=>"0", "ToCity"=>"DENVER", "FromZip"=>"80204", "SmsSid"=>"SMee75840411b997aa68ed3e6fa55be0ed", "FromState"=>"CO", "SmsStatus"=>"received", "FromCity"=>"DENVER", "Body"=>"sup", "FromCountry"=>"US", "To"=>"+17209032094", "ToZip"=>"80204", "MessageSid"=>"SMee75840411b997aa68ed3e6fa55be0ed", "AccountSid"=>"ACc923e9140096eb111ad3aa52eb0a47b3", "From"=>"+17203197009", "ApiVersion"=>"2010-04-01"}

  # GET /surveys
  # GET /surveys.json
  def index
    @surveys = Survey.all
  end

  # GET /surveys/1
  # GET /surveys/1.json
  def show
  end

  # GET /surveys/new
  def new
    @survey = Survey.new
  end

  # GET /surveys/1/edit
  def edit
  end

  # POST /surveys
  # POST /surveys.json
  def create
    if survey_params[:multi].blank?
      @survey = Survey.new(survey_params)
      respond_to do |format|
        if @survey.save
          format.html { redirect_to @survey, notice: 'Survey was successfully created.' }
        else
          format.html { render :new }
        end
      end
    else
      Survey.create_multiple(survey_params)
      respond_to do |format|
          format.html { redirect_to surveys_path, notice: 'Surveys were successfully created.' }
      end
    end

  end

  # PATCH/PUT /surveys/1
  # PATCH/PUT /surveys/1.json
  def update
    respond_to do |format|
      if @survey.update(survey_params)
        format.html { redirect_to @survey, notice: 'Survey was successfully updated.' }
        format.json { render :show, status: :ok, location: @survey }
      else
        format.html { render :edit }
        format.json { render json: @survey.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /surveys/1
  # DELETE /surveys/1.json
  def destroy
    @survey.destroy
    respond_to do |format|
      format.html { redirect_to surveys_url, notice: 'Survey was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_survey
      @survey = Survey.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def survey_params
      params.require(:survey).permit(:name, :number, :multi)
    end
end
