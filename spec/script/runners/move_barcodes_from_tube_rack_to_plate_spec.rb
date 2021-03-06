require 'rails_helper'

require Rails.root.to_s+'/script/runners/move_barcodes_from_tube_rack_to_plate'

RSpec.describe 'MoveBarcodesFromTubeRackToPlate' do
  NUM_WELLS = 3

  let(:activity) { create :activity }
  let(:step) { create :step, activity: activity, state: Step::STATE_RUNNING }

  let(:barcodes) {
    NUM_WELLS.times.map{|i| "FR00#{i}"}
  }
  let(:padded_locations) {
    NUM_WELLS.times.map{|i| "A0#{i}"}
  }

  let(:locations) {
    NUM_WELLS.times.map{|i| "A#{i}"}
  }
  let(:wells_for_rack) {
    NUM_WELLS.times.map do |i|
      asset = create(:asset, barcode: barcodes[i])
      asset.facts << create(:fact, predicate: 'a', object: 'Tube')
      asset.facts << create(:fact, predicate: 'location', object: padded_locations[i])
      asset
    end
  }
  let(:wells_for_plate) {
    NUM_WELLS.times.map do |i|
      asset = create(:asset)
      asset.facts << create(:fact, predicate: 'a', object: 'Well')
      asset.facts << create(:fact, predicate: 'location', object: locations[i])
      asset
    end
  }
  let(:tube_rack) {
    asset = create :asset
    asset.facts << create(:fact, predicate: 'a', object: 'TubeRack')
    asset.facts << wells_for_rack.map{|a| create(:fact, predicate: 'contains', object_asset: a)}
    asset
  }
  let(:plate) {
    asset = create :asset
    asset.facts << create(:fact, predicate: 'a', object: 'Plate')
    asset.facts << wells_for_plate.map{|a| create(:fact, predicate: 'contains', object_asset: a)}
    asset
  }

  context 'when run with a tube rack and a plate' do
    it 'adds the barcodes of the tube rack into the wells of the plate' do
      group = create(:asset_group, assets: [plate, tube_rack])
      updates = MoveBarcodesFromTubeRackToPlate.new(asset_group: group).process
      changes = updates.to_h

      expect(changes[:add_facts].select{|t| t[1] == 'barcode'}.count).to eq(NUM_WELLS)

      wells_for_plate.each_with_index do |w, pos|
        expect(changes[:add_facts]).to include(
          [w.uuid, 'barcode', barcodes[pos]])
      end
      expect{
        updates.apply(step)
        wells_for_plate.each(&:reload)
      }.to change{wells_for_plate.first.barcode}.from(nil).to(barcodes.first)
    end
    it 'removes the barcodes from the tubes of the tube rack' do
      group = create(:asset_group, assets: [plate, tube_rack])
      updates = MoveBarcodesFromTubeRackToPlate.new(asset_group: group).process
      changes = updates.to_h

      expect(changes[:remove_facts].select{|t| t[1] == 'barcode'}.count).to eq(NUM_WELLS)

      wells_for_rack.each_with_index do |w, pos|
        expect(changes[:remove_facts]).to include(
          [w.uuid, 'barcode', barcodes[pos]])
      end
      expect{
        updates.apply(step)
        wells_for_rack.each(&:reload)
      }.to change{wells_for_rack.first.barcode}.from(barcodes.first).to(nil)
    end

  end
end
