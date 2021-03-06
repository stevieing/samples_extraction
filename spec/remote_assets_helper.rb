module RemoteAssetsHelper
	def build_remote_plate(opts = {})
		purpose = double('purpose', name: 'A purpose')
		obj = {
			uuid: SecureRandom.uuid,
			wells: [build_remote_well('A1'), build_remote_well('A4')],
			plate_purpose: purpose,
			type: 'plates'
		}.merge(opts)
		my_double = double('remote_asset', obj)
		allow(my_double).to receive(:attributes).and_return(obj)

		allow(my_double).to receive(:class).and_return(Sequencescape::Plate)

		my_double
	end

	def build_remote_well(location, opts={})
		obj = {
			type: 'wells',
			aliquots: [build_remote_aliquot], location: location,
			position: { "name" => location }, uuid: SecureRandom.uuid
		}.merge(opts)
		well=double('well', obj)
		allow(well).to receive(:attributes).and_return(obj)
		allow(well).to receive(:class).and_return(Sequencescape::Well)
		well
	end

	def build_remote_tube(opts = {})
		purpose = double('purpose', name: 'A purpose')

		obj = {
			uuid: SecureRandom.uuid,
			type: 'tubes',
			plate_purpose: purpose,
			aliquots: [build_remote_aliquot]
			}.merge(opts)

		my_double = double('remote_asset', obj)
		allow(my_double).to receive(:attributes).and_return(obj)

		allow(my_double).to receive(:class).and_return(Sequencescape::Tube)
		my_double
	end

	def build_remote_aliquot(opts={})
		double('aliquot', {sample: build_remote_sample, study: build_study}.merge(opts))
	end

	def build_study(opts={})
		double('study', {name: 'STDY', uuid: SecureRandom.uuid})
	end

	def build_remote_sample(opts={})
		attrs_for_sample = {
			sanger_sample_id: 'TEST-123',
			name: 'a sample name',
			sample_metadata: double('sample_metadata', {supplier_name: 'a supplier', sample_common_name: 'specie'}),
			#sanger: double('sanger', { sample_id: 'TEST-123', name: 'a sample name'}),
			uuid: SecureRandom.uuid,
			#supplier: double('supplier', {sample_name: 'a supplier'}),
			updated_at: Time.now.to_s
		}.merge(opts)

		sample = double('sample', attrs_for_sample)
		allow(sample).to receive(:attributes).and_return(attrs_for_sample)
		sample
	end

	def stub_client_with_asset(client, asset)
		type = (asset.class==Sequencescape::Plate) ? :plate : :tube
	  allow(client).to receive(:find_by_uuid).with(asset.uuid).and_return(asset)
	  allow(client).to receive(:find_by_uuid).with([asset.uuid]).and_return([asset])
		allow(client).to receive(:get_remote_asset).with(asset.uuid).and_return(asset)
		allow(client).to receive(:get_remote_asset).with([asset.uuid]).and_return([asset])
	  if asset.respond_to?(:barcode)
			allow(client).to receive(:get_remote_asset).with(asset.barcode).and_return(asset)
			allow(client).to receive(:get_remote_asset).with([asset.barcode]).and_return([asset])
		end
	end

	def stub_client_with_assets(client, assets)
		assets.each {|asset| stub_client_with_asset(client, asset) }
		if (assets.first.respond_to?(:barcode))
    	allow(client).to receive(:get_remote_asset).with(assets.map(&:barcode)).and_return(assets)
    end
    allow(client).to receive(:get_remote_asset).with(assets.map(&:uuid)).and_return(assets)
    allow(client).to receive(:find_by_uuid).with(assets.map(&:uuid)).and_return(assets)
	end

end
