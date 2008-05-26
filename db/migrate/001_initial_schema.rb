class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table "articles" do |t|
      t.integer  "kind"
      t.integer  "user_id"
      t.string   "slug"
      t.string   "title"
      t.text     "body"
      t.text     "extended"
      t.integer  "comment_period"
      t.integer  "comments_count", :default => 0, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "published_at"
    end

    add_index "articles", ["slug"], :name => "index_articles_on_slug"
    add_index "articles", ["slug", "published_at"], :name => "index_articles_on_slug_and_published_at"
    add_index "articles", ["kind", "published_at"], :name => "index_articles_on_kind_and_published_at"

    create_table "comments" do |t|
      t.integer  "article_id"
      t.integer  "user_id"
      t.string   "author_name"
      t.string   "author_email"
      t.string   "author_url"
      t.string   "author_ip",    :limit => 16
      t.text     "body"
      t.datetime "created_at"
    end

    add_index "comments", ["article_id"], :name => "index_comments_on_article_id"

    create_table "rejects" do |t|
      t.integer  "article_id"
      t.integer  "user_id"
      t.string   "author_name"
      t.string   "author_email"
      t.string   "author_url"
      t.string   "author_ip",    :limit => 16
      t.text     "body"
      t.text     "tofu"
      t.datetime "created_at"
    end

    create_table "taggings" do |t|
      t.integer  "tag_id"
      t.integer  "article_id"
      t.datetime "created_at"
    end

    add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
    add_index "taggings", ["article_id"], :name => "index_taggings_on_article_id"

    create_table "tags" do |t|
      t.string   "name"
      t.integer  "taggings_count", :default => 0, :null => false
      t.datetime "created_at"
    end

    add_index "tags", ["name"], :name => "index_tags_on_name"

    create_table "users" do |t|
      t.string   "name"
      t.string   "login"
      t.string   "email"
      t.string   "crypted_password",          :limit => 40
      t.string   "salt",                      :limit => 40
      t.string   "remember_token"
      t.datetime "remember_token_expires_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "users", ["login"], :name => "index_users_on_login"

    create_table "versions" do |t|
      t.integer  "versionable_id"
      t.string   "versionable_type"
      t.integer  "number"
      t.text     "yaml"
      t.datetime "created_at"
    end

    add_index "versions", ["versionable_id", "versionable_type"], :name => "index_versions_on_versionable_id_and_versionable_type"
  end

  def self.down
    drop_table "articles"
    drop_table "comments"
    drop_table "rejects"
    drop_table "taggings"
    drop_table "tags"
    drop_table "users"
    drop_table "versions"
  end
end
