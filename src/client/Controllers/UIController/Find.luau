--!strict

-- Looks up an authored element by name and class; warns with the path when it is missing
-- so a renamed element disables one feature visibly instead of erroring.
return function(parent: Instance, name: string, class: string): any
	local found = parent:FindFirstChild(name, true)
	if found and found:IsA(class) then
		return found
	end
	warn(`[UI] {parent:GetFullName()} needs a {class} named {name}`)
	return nil
end
