# Sequel::AuditByDay

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'sequel-audit_by_day'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sequel-audit_by_day

## Usage

Given following models:

```ruby
#
# Sequel.migration do
#   change do
#     create_table :users do
#       primary_key :id
#       FalseClass  :admin, default: false, null: false
#     end
#   end
# end
#
class User < Sequel::Model
  def audit_kind
    admin ? "admin" : "user"
  end
end
#
# Sequel.migration do
#   change do
#     create_table :posts do
#       primary_key :id
#     end
#     create_table :post_versions do
#       primary_key :id
#       foreign_key :master_id, :posts, on_delete: :cascade, deferrable: true
#       Time        :created_at
#       Time        :expired_at
#       Date        :valid_from
#       Date        :valid_to
#       String      :title
#       index [:master_id, :created_at, :valid_from, :valid_to]
#     end
#     create_table :post_audits do
#       primary_key :id
#       Date        :for
#       foreign_key :post_id, :posts, on_delete: :cascade, deferrable: true
#       index [:post_id, :for], unique: true
#     end
#     create_table :post_audit_versions do
#       primary_key :id
#       foreign_key :master_id, :post_audits, on_delete: :cascade, deferrable: true
#       Time        :created_at
#       Time        :expired_at
#       Date        :valid_from
#       Date        :valid_to
#       foreign_key :title_updated_at, Time
#       foreign_key :title_updated_by_user_id, :users, on_delete: :set_null
#       foreign_key :title_updated_by_admin_id, :users, on_delete: :set_null
#       index [:master_id, :created_at, :valid_from, :valid_to]
#     end
#   end
# end
#
class Post < Sequel::Model
  plugin :bitemporal, version_class: PostVersion,
                      audit_class: PostAudit,
                      audit_updated_by_method: :updated_by

  one_to_many :audits, class: "PostAudit"
  delegate :updated_by, to: :pending_or_current_version, allow_nil: true
end
class PostVersion < Sequel::Model
  attr_accessor :updated_by
end
class PostAudit < Sequel::Model
  plugin :bitemporal, version_class: PostAuditVersion
  plugin :audit_by_day, foreign_key: :post_id
end
class PostAuditVersion < Sequel::Model
end
```

Then you can record changes like this:

```
user = User.create
admin = User.create admin: true

post = Post.new.update_attributes({
  title: "First post",
  updated_by: admin,
})

post.update_attributes({
  title: "First post updated",
  updated_by: user
})
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
