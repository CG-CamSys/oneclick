class RemoveL12yContent < ActiveRecord::Migration
  def change

    execute "DROP TABLE IF EXISTS #{quote_table_name('l12y_contents')}"

    unless column_exists?(:translations, :locale)
      add_column :translations, :locale, :string
    end

    unless column_exists?(:translations, :value)
      add_column :translations, :value, :text
    end
  end
end
