# Stores the specific data for a removed status.
#
# This model is immutable
class Removal < ApplicationRecord
  has_one :status, as: :details

  enum removal_type: { gone: "gone",
                       redirect: "redirect",
                       vanish: "vanish" }

  def readonly?
    !new_record?
  end
end
