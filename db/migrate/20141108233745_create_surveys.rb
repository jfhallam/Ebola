class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.string :name
      t.string :number
      t.string :parsed_number
      t.boolean :q0
      t.boolean :q1
      t.boolean :q2
      t.boolean :q3
      t.boolean :q4
      t.boolean :q5
      t.boolean :q6
      t.boolean :q7
      t.boolean :q8
      t.boolean :q9
      t.datetime :completed_at
      t.integer :risk_score
      t.integer :symptom_score
      t.integer :score
      t.string :risk_level
      t.string :exposure_risk
      t.timestamps
    end
  end
end
