json.array!(@surveys) do |survey|
  json.extract! survey, :id, :name, :number
  json.url survey_url(survey, format: :json)
end
