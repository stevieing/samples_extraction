class AssetGroupsAsset < ActiveRecord::Base
  belongs_to :asset
  belongs_to :asset_group
end
