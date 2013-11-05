class AddColumnsForEsp < ActiveRecord::Migration
  def change
    add_column :providers, :url, :string, :limit => 256
    # change_column advanced_notice_minutes
  end

end
