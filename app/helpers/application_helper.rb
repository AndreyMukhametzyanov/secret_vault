module ApplicationHelper
  def form_control_class(object, attribute, base_class: "form-control")
    [ base_class, ("is-invalid" if object.errors[attribute].any?) ].compact.join(" ")
  end
end
