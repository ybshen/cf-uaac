#--
# Cloud Foundry 2012.02.03 Beta
# Copyright (c) [2009-2012] VMware, Inc. All Rights Reserved.
#
# This product is licensed to you under the Apache License, Version 2.0 (the "License").
# You may not use this product except in compliance with the License.
#
# This product includes a number of subcomponents with
# separate copyright notices and license terms. Your use of these
# subcomponents is subject to the terms and conditions of the
# subcomponent's license, as noted in the LICENSE file.
#++

require 'set'
require 'cli/common'
require 'uaa'

module CF::UAA

class GroupCli < CommonCli

  topic "Groups", "group"

  def gname(name) name || ask("Group name") end

  desc "groups [filter]", "List groups", :attrs, :start, :count do |filter|
    scim_common_list(:group, filter)
  end

  desc "group get [name]", "Get specific group information", :attrs do |name|
    pp scim_request { |sr| scim_get_object(sr, :group, gname(name), opts[:attrs]) }
  end

  desc "group add [name]", "Adds a group" do |name|
    pp scim_request { |scim| scim.add(:group, displayName: gname(name)) }
  end

  desc "group delete [name]", "Delete group" do |name|
    pp scim_request { |scim|
      scim.delete(:group, scim.id(:group, gname(name)))
      "success"
    }
  end

  def id_set(objs)
    objs.each_with_object(Set.new) {|o, s|
      id = o.is_a?(String)? o: (o["id"] || o["value"] || o["memberid"])
      raise BadResponse, "no id found in response of current members" unless id
      s << id
    }
  end

  def update_members(scim, name, attr, users, add = true)
      group = scim_get_object(scim, :group, gname(name))
      old_ids = id_set(group[attr] || [])
      new_ids = id_set(scim.ids(:user, *users))
      if add
        raise "not all users found, none added" unless new_ids.size == users.size
        group[attr] = (old_ids + new_ids).to_a
        raise "no new users given" unless group[attr].size > old_ids.size
      else
        raise "not all users found, none deleted" unless new_ids.size == users.size
        group[attr] = (old_ids - new_ids).to_a
        raise "no existing users to delete" unless group[attr].size < old_ids.size
        group.delete(attr) if group[attr].empty?
      end
      scim.put(:group, group)
      "success"
  end

  desc "member add [name] [users...]", "add members to a group" do |name, *users|
    pp scim_request { |scim| update_members(scim, name, "members", users) }
  end

  desc "member delete [name] [users...]", "remove members from a group" do |name, *users|
    pp scim_request { |scim| update_members(scim, name, "members", users, false) }
  end

  desc "group reader add [name] [users...]", "add users who can read the members" do |name, *users|
    pp scim_request { |scim| update_members(scim, name, "readers", users) }
  end

  desc "group reader delete [name] [users...]", "delete users who can read members" do |name, *users|
    pp scim_request { |scim| update_members(scim, name, "readers", users, false) }
  end

  desc "group writer add [name] [users...]", "add users who can modify group" do |name, *users|
    pp scim_request { |scim| update_members(scim, name, "writers", users) }
  end

  desc "group writer delete [name] [users...]", "remove user who can modify group" do |name, *users|
    pp scim_request { |scim| update_members(scim, name, "writers", users, false) }
  end

end

end
