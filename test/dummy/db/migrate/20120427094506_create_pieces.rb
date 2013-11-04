class CreatePieces < ActiveRecord::Migration
  def change
    create_table :pieces do |t|
      t.string :str
      t.integer :int
      t.integer :piece_id

      t.timestamps
    end
  end
end
