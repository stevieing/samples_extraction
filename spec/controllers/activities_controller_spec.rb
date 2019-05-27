require 'rails_helper'

RSpec.describe ActivitiesController, type: :controller do

  context "when scanning a new kit" do
    setup do
      @activity_type = FactoryBot.create :activity_type
      @kit_type = FactoryBot.create :kit_type, :activity_type => @activity_type
      @kit = FactoryBot.create :kit, {:kit_type => @kit_type}
      @instrument = FactoryBot.create :instrument
      @instrument.activity_types << @activity_type
    end

    it "create a new activity of the activity type of the kit" do
      count = @kit.kit_type.activity_type.activities.count
      post :create,  params: { activity: { :kit_barcode => @kit.barcode, :instrument_barcode => @instrument.barcode}}
      @kit.kit_type.activity_type.activities.reload
      assert_equal @kit.kit_type.activity_type.activities.count, count + 1
      assert_equal @activity_type.activities.count, count + 1
    end

    context "when scanning a new barcode" do
      setup do
        @asset = FactoryBot.create :asset, {:barcode => '1'}

        @facts = [
          ['is_a', 'Tube'],
          ['is_a', 'ReceptionTube'],
          ['aliquotType', 'DNA']
        ].map do |a,b|
          FactoryBot.create :fact, { :predicate => a, :object => b}
        end

        @step_type = FactoryBot.create :step_type, :name => 'Step B'
        @step_type2 = FactoryBot.create :step_type, :name => 'Step A'


        @step_type.activity_types << @activity_type
        @step_type2.activity_types << @activity_type

        @condition_group = FactoryBot.create :condition_group, :step_type => @step_type

        @conditions = [
          ['is_a', 'ReceptionTube'],
          ['aliquotType', 'DNA']
        ].map do |a,b|
          FactoryBot.create :condition, {
            :predicate => a, :object => b, :condition_group_id => @condition_group.id}
        end


        @asset.facts << @facts

        @asset_group = FactoryBot.create :asset_group

        @asset.asset_groups << @asset_group
        @activity = FactoryBot.create :activity, :activity_type => @activity_type, :asset_group => @asset_group

        @activity_type.activities << @activity

        @step = FactoryBot.create :step, {
          :step_type_id => @step_type.id,
          :activity_id => @activity.id,
          :asset_group_id => @asset_group.id
        }
      end

      it "identify all the step types" do
        assert_equal @activity.step_types, [@step_type, @step_type2]
      end

      it "identify the possible step types" do
        assert_equal @activity.step_types_for([@asset]), [@step_type]
      end

      it "identify the steps done" do
        assert_equal @activity.steps_for(@asset_group.assets), [@step]
      end
    end

  end

end