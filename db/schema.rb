# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141108233745) do

  create_table "surveys", force: true do |t|
    t.string   "name"
    t.string   "number"
    t.string   "parsed_number"
    t.boolean  "q0"
    t.boolean  "q1"
    t.boolean  "q2"
    t.boolean  "q3"
    t.boolean  "q4"
    t.boolean  "q5"
    t.boolean  "q6"
    t.boolean  "q7"
    t.boolean  "q8"
    t.boolean  "q9"
    t.datetime "completed_at"
    t.integer  "risk_score"
    t.integer  "symptom_score"
    t.integer  "score"
    t.string   "risk_level"
    t.string   "exposure_risk"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
