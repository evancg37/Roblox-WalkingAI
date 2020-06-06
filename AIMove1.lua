threshold_distcalc = 25
head = script.Parent.Head
goalpoint_threshold = 1.5
tickrate = 16
jump_error = 1

DEBUG = true

local walkdebug, rundebug, jp, npp, cdd

if DEBUG then
	walkdebug = Instance.new("Part", script.Parent)
	walkdebug.Name = "WalkDebug"
	walkdebug.Size = Vector3.new(3, 0.5, 3)
	walkdebug.Color = Color3.new(0.6, 1, 0.6)
	walkdebug.Anchored = true
	walkdebug.TopSurface = Enum.SurfaceType.Smooth
	walkdebug.CanCollide = false
	
	rundebug = walkdebug:Clone()
	rundebug.Color = Color3.new(0.6, 0.6, 0.6)
	rundebug.Name = "RunDebug"
	rundebug.Parent = workspace
	
	jp = Instance.new("Part", script.Parent)
	jp.Name = "JumpPart"
	jp.Shape = Enum.PartType.Ball
	jp.Anchored = true
	jp.CanCollide = false
	jp.Transparency = 0.5
	jp.Color = Color3.new(0.6, 0.3, 0.8)
	jp.Size = Vector3.new(1, 1, 1)
	
	npp = Instance.new("Part", script.Parent)
	npp.Name = "NearestMarker"
	npp.Anchored = true
	npp.CanCollide = false
	npp.Size = Vector3.new(1.4, 1.4, 1.4)
	npp.Shape = Enum.PartType.Ball
	npp.Color = Color3.new(0, 0.8, 0.8)

	cdd = Instance.new("Part", script.Parent)
	cdd.Name = "JumppointMarker"
	cdd.Anchored = true
	cdd.CanCollide = false
	cdd.Size = Vector3.new(1.4, 1.4, 1.4)
	cdd.Shape = Enum.PartType.Ball
	cdd.Color = Color3.new(0.8, 0.8, 0)
end

function DEBUG_PRINT(msg)
	if DEBUG then
		print ("AIMove debug: " .. msg)
	end
end

function walkToPoint(pos)
	local cframe = CFrame.new(pos, head.Position) * CFrame.new(Vector3.new(0, 0, 20)) --todo improve run point, need angle
	head.Parent.Humanoid:MoveTo(cframe.Position)
	if DEBUG then
		walkdebug.Position = pos
		rundebug.Position = cframe.Position
	end
end

function getJumplength()
	local jumplength = 4.9 + (head.Parent.Humanoid.WalkSpeed * 0.49) 
	return jumplength - jump_error
end



function canIJumpIt(platform) --Form diagonal jump from current position
	local jumplength = getJumplength()
	local jumppoint = head.CFrame * CFrame.new(Vector3.new(0, 0, -jumplength))
	if DEBUG then jp.Position = jumppoint.Position end 
	if isPointInXZBoundary(jumppoint, platform) then
		DEBUG_PRINT "I can jump this!"
		return true
	end
	DEBUG_PRINT "ITS NOT SAFE!"
	return false
end

function getAngleToGoalpost(goalpost)
	local dist = (goalpost.Position - head.Position)
	local angle = math.atan2(dist.Z, dist.X)
	return angle
end

function convertAngleToNSEW(rad)
	if rad >= math.pi * 0.25 and rad < math.pi * 0.75 then
		return "north"
		--print "Looks like north"
	elseif rad >= math.pi * 0.75 and rad < math.pi * 1.25 then
		return "west"
		--print "Looks like west"
	elseif rad >= math.pi * 1.25 and rad < math.pi * 1.75 then
		return "south"
		--print "Looks like south"
	elseif rad >= math.pi * 1.75 or rad < math.pi * 0.25 then
		return "east"
		--print "Looks like east"
	else
		print "AIMove: No angles found for conversion"
		return nil
	end
end

function waitReachPoint(point, platform)
	DEBUG_PRINT "Now waiting to reach a point."
	while true do
		wait()
		local head_surfacepoint = getPointOnSurface(head.Position, platform)
		local goal_surfacepoint = getPointOnSurface(point, platform)
		if (goal_surfacepoint-head_surfacepoint).magnitude < goalpoint_threshold then
			break
		end
	end
	DEBUG_PRINT "Done waiting for reaching a point."
end

function getPointOnSurface(ref, platform)
	return Vector3.new(ref.X, platform.Position.Y + platform.Size.Y/2, ref.Z)
end

function LIVE_DEBUG()
	if workspace["LIVE DEBUG"].Value == true then
		DEBUG_PRINT "Breakpoint"
	end
end

--Given my positon, draw a ray towards a goal platform, and then find the out_origin and in_destination points on the ray on the platforms
function findNearestPointInBoundary(platform, myplatform) --todo fix, at first glance 0 idea and this is where confusion lies
	DEBUG_PRINT("Calculating ray to " .. platform.Name)
	DEBUG_PRINT("For ray calculation, my platform is " .. myplatform.Name)
	if workspace["LIVE DEBUG"].Value == true then
		myplatform.Color = Color3.New(1, 0, 0)
		DEBUG_PRINT "Breakpoint"
		wait(50)
	end
	local origin = getPointOnSurface(head.Position, myplatform)
	local look = getPointOnSurface(platform.Position, platform)
	
	local goray = Ray.new(origin, look - origin) --Ray to find hits towards the platform
	local _, in_destination = workspace:FindPartOnRayWithWhitelist(goray, {platform})
	
	local backray = Ray.new(look, origin-look) --Ray to find hit at the origin
	local _, out_origin = workspace:FindPartOnRayWithWhitelist(backray, {myplatform})
	
	if DEBUG then
		npp.Position = in_destination
		cdd.Position = out_origin
	end
	--print("Hitpart:" .. hitpart.Name)
	return in_destination, out_origin 
end

function isPointInXZBoundary(point, platform, fudge)
	local x_1 = platform.Position.X + (platform.Size.X / 2)
	local x_2 = platform.Position.X - (platform.Size.X / 2)
	local z_1 = platform.Position.Z + (platform.Size.Z / 2)
	local z_2 = platform.Position.Z - (platform.Size.Z / 2)
	if fudge then
		x_1 = x_1 * 1
		x_2 = x_2 * 1 --todo remove
		z_1 = z_1 * 1
		z_2 = z_2 * 1
	end
	local within_x = (point.X < x_1 or point.X < x_2) and (point.X > x_1 or point.X > x_2)
	local within_z = (point.Z < z_1 or point.Z < z_2) and (point.Z > z_1 or point.Z > z_2)
	if DEBUG then
		workspace.Markers:ClearAllChildren()
		createMarker(Vector3.new(x_1, 4, z_1), Color3.new(1, 1, 1))
		createMarker(Vector3.new(x_2, 4, z_1), Color3.new(1, 1, 1))
		createMarker(Vector3.new(x_1, 4, z_2), Color3.new(1, 1, 1))
		createMarker(Vector3.new(x_2, 4, z_2), Color3.new(1, 1, 1))
	end
	if within_x and within_z then return true else return false end
end

function waitReachBoundary(platform, goaly)
	DEBUG_PRINT "Now waiting to reach a boundary."
	while true do
		wait()
		if isPointInXZBoundary(head.Position, platform, true) then -- and math.abs(goaly - head.Position.Y) < 2 then
			break
		end
	end
	DEBUG_PRINT "Done waiting for reaching a boundary."
end

function jumpToPointOnPlatform(origin, destination, platform)
	local walkpoint = CFrame.new(destination, origin) * CFrame.new(Vector3.new(0, 2, 15)) --10 units behind destination facing origin
	if DEBUG then jp.Position = walkpoint.Position end
	head.Parent.Humanoid:MoveTo(walkpoint.Position)
	DEBUG_PRINT "JUMP!"
	head.Parent.Humanoid.Jump = true
	waitReachBoundary(platform, origin.Y)
	DEBUG_PRINT "Phew, made it!"
end

function sortDistances(routes, num)
	local result = {}
	local i = 1

	--print("Routes: " .. table.getn(routes))
	while #routes > 0 and i <= num do 
		local mindist, mintarg, mi
		mindist = math.huge
		for index, route in ipairs(routes) do
			local dist = route[1]
			if dist < mindist then
				mindist = dist
				mintarg = route[2]
				mi = index
			end
		end
		table.insert(result, mintarg)
		table.remove(routes, mi)
		i = i + 1
	end
	return result
end

function getNearestPlatforms(pos, platforms, num) --For a position, find the nearest platforms to that position
	if num == nil then num = 6 end
	local routes = {}
	for _, targ in pairs (platforms) do
		local dist = (targ.Position - pos).magnitude
		if dist < threshold_distcalc then
			table.insert(routes, {dist, targ})
		end
	end
	routes = sortDistances(routes, num) --Sort routes to get min distance first
	--print ("First result:")
	--print(routes[1])
	return routes -- Returns list of parts that are close (set threshold, threshold will be replaced by minimum corner distance of part A)
end

function getCloserPlatforms(platforms, goal) --todo improve, use something instead of head distance
	local result = {}
	
	local compare_dist = (head.Position - goal).magnitude
	for _, platform in pairs(platforms) do
		local dist = (getPointOnSurface(platform.Position, platform) - goal).magnitude
		if dist < compare_dist then
			table.insert(result, platform)
			if DEBUG then platform.BrickColor = BrickColor.Green() end
		end
	end
	return result
end

function getMyPlatform(platforms) --todo optimize with rays
	local mindist = math.huge
	local minplat
	for _, platform in pairs(platforms) do
		local plat_top = getPointOnSurface(platform.Position, platform)
		local head_top = getPointOnSurface(head.Position, platform)
		local dist = (plat_top - head_top).magnitude
		if dist < mindist then
			minplat = platform
			mindist = dist
		end
	end
	if isPointInXZBoundary(head.Position, minplat, true) then
		if DEBUG then minplat.Color = Color3.new(0.4, 0.4, 0.7) end
		return minplat
	end
	return nil
end

-----------------------------------------------------------------------

function goToGoal4(goalpost, course)
	while true do 
		wait(1/tickrate)
		--get my platform, if any
		--find my feet position on platform, if any
		--only do logic based on platforms. if we dont have a platform, then stop for now
		
		--knowing my platform, use corner/midpoint comparison to find platforms this platform is near
		--of the near platforms, choose the one thats me closer to the goal
		--calculate if we need to jump from platform a to b
		--if we do, then determine the shortest jump distance and head towards jump_from
		--routinely check to see when I can make the jump. when I can, do it
		--dont wait for reaching this platform, just keep doing the loop because i never have to jump to my own platform
		--if we dont have a platform, we are considered falling - dont do anything while falling
	end
end


timeout_max = 20

function goToGoal3(goalpost, course)
	local timeout = timeout_max
	local lastdist
	while timeout > 0 do
		wait(1/tickrate)
		local goal = goalpost.Position + Vector3.new(0, 2, 0)
		
		--debug
		if DEBUG then
			for _, platform in pairs(course:GetChildren()) do
				platform.BrickColor = BrickColor.Gray()
			end
		end
		--
		
		if (head.Position - goal).magnitude < 7 then
			DEBUG_PRINT "AI succesfully reached goal!"
			head.Parent.Humanoid:MoveTo(head.Position)
			return true
		end
		
		--what would I think if i was platforming?
		--first determine the platforms i can jump to
		--then determine which of those gets me closer to the goal
		--then if i can jump to it, jump from jump point to platform
		---if i cant jump it then give up, or seek out some other way
		---a jump point is the smallest distance between the two platforms
		--once made the jump, then start over
		
		--logic should be
		--look at all the platforms nearest to me (reachable platforms)
		--out of them, which one gets you closest to the goal? It would have the smallest XZ distance to the goal from all corners
		--if there is my platform, and there is goal platform, then calc the jump distnace (distance between smallest found jump points)
		--if the jump looks feasible, head towards the starting jump point - if infeasible then give up? - if too small then just walk to goal b
		--recognize when I can jump, and jump it
		--each tick, check if i can jump to the goal - if i can then execute jump
		
		--Get near platforms which are good
		--goodplatforms are ahead of mine
		--Also get my platform, and the good ones are not mine
		local platforms = course:GetChildren()
		local good_platforms = getCloserPlatforms(platforms, goal)
		local my_platform = getMyPlatform(platforms)
		for i, plat in pairs(good_platforms) do 
			if plat == my_platform then
				table.remove(good_platforms, i)
			end
		end
		local near_platforms = getNearestPlatforms(head.Position, good_platforms, 3)
		local nearest_platform = near_platforms[1]
		if nearest_platform then
			if DEBUG then nearest_platform.Color = Color3.new(0.8, 1, 0) end
			if my_platform ~= nil then --If we are on a platform
				if workspace["LIVE DEBUG"].Value == true then 
					print "Breakpoint"
				end
				local gopos, origpos = findNearestPointInBoundary(nearest_platform, my_platform) --Find the nearest point in nearest_platform to me
				if gopos then --If we found a point like this
					local myjumplength = getJumplength()
					local proposed_jumplength = (gopos-origpos).magnitude --Find out if we jumped from the start to finish is within our jump length
					if proposed_jumplength <= 1.8 then 
						if (gopos - getPointOnSurface(head.Position, my_platform)).magnitude < 3 then
							DEBUG_PRINT "Traversed unnecesssary platform."
							walkToPoint(goal) --Just move towards goal across platform
						else
							DEBUG_PRINT "Moving across platform."
							walkToPoint(gopos) --Just walk towards the goal point
						end
					elseif myjumplength > proposed_jumplength + jump_error + 0.6 then
						DEBUG_PRINT "Feasible jump detected"
						local distfromjumppoint = (getPointOnSurface(head.Position, my_platform) - origpos).magnitude
						DEBUG_PRINT ("Dist from jump point: " .. distfromjumppoint)
						if distfromjumppoint < 2 then --If we are close to the jump point
							DEBUG_PRINT "Already close, let's jump!"
							head.JumpSpecial:Play()
							jumpToPointOnPlatform(head.Position, gopos, nearest_platform)
						else --Walk towards the jump point
							DEBUG_PRINT "Getting closer to jump point"
							walkToPoint(origpos)
							waitReachPoint(origpos, my_platform)
							DEBUG_PRINT "Doing planned jump..."
							head.JumpNormal:Play()
							jumpToPointOnPlatform(head.Position, gopos, nearest_platform)
						end
					else
						DEBUG_PRINT "Cant jump, getting closer to edge"
						--Find nearest pair point and head for it 
						local jumpfrom, jumpto = findShortestJumpDistance(my_platform, nearest_platform)
						walkToPoint(jumpfrom)
					end
				else --No destination
					print "AIMove: AI is Lost!"
				end
			else
				walkToPoint(nearest_platform.Position + Vector3.new(0, nearest_platform.Size.Y/2, 0)) --If we are not on a platform, head towards one.
			end
		else
			DEBUG_PRINT "No near platforms, heading towards goal"
			walkToPoint(goal)
			--timeout = timeout - 1
		end
		if lastdist then
			if (head.Position-goal).magnitude <= (lastdist - 0.1) then
				lastdist = (head.Position-goal).magnitude - 0.1
				timeout = timeout_max
			else
				lastdist = (head.Position-goal).magnitude
				timeout = timeout - 1
				if timeout <= timeout_max - 4 then 
					DEBUG_PRINT "Try jump"
					head.Parent.Humanoid.Jump = true
					timeout = timeout - 10
				end
			end
		else
			lastdist = (head.Position-goal).magnitude
		end
	end
	print "AIMove: Timeout"
end


function createMarker(pos, color)
	local p = Instance.new("Part", workspace.Markers)
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 0.5
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(1.2, 0.8, 1.2)
	if color ~= nil then
		p.Color = color
	else
		p.Color = Color3.new(0.4, 0.4, 0.4)
	end
	p.Position = pos
	return p
end

function createEdgeSpaces(pos1, pos2, divisions, mark)
	local markers = {}
	for i = 1, divisions do
		local newpos = pos2:Lerp(pos1, i * (1/divisions))
		table.insert(markers, i, newpos)
		if mark then createMarker(newpos) end
	end
	return markers
end

function getCornersOnEdge(part, direction)
	local pos1, pos2
	if direction == "north" then
		pos1 = part.Position + Vector3.new(part.Size.X/-2, part.Size.Y/2, part.Size.Z/2)
		pos2 = part.Position + Vector3.new(part.Size.X/2, part.Size.Y/2, part.Size.Z/2)
	elseif direction == "south" then
		pos1 = part.Position + Vector3.new(part.Size.X/-2, part.Size.Y/2, part.Size.Z/-2)
		pos2 = part.Position + Vector3.new(part.Size.X/2, part.Size.Y/2, part.Size.Z/-2)
	elseif direction == "east" then
		pos1 = part.Position + Vector3.new(part.Size.X/2, part.Size.Y/2, part.Size.Z/-2)
		pos2 = part.Position + Vector3.new(part.Size.X/2, part.Size.Y/2, part.Size.Z/2)
	elseif direction == "west" then
		pos1 = part.Position + Vector3.new(part.Size.X/-2, part.Size.Y/2, part.Size.Z/-2)
		pos2 = part.Position + Vector3.new(part.Size.X/-2, part.Size.Y/2, part.Size.Z/2)
	end
	return pos1, pos2
end

function getEdgePoints(pa, pb, mark)
	--get ray between pa and pb
	--find out angle of ray
	--for pa, choose the correct face closest towards pb
	--use size and position to then mark the edge
	local ray = pb.Position - pa.Position
	local angle = math.atan2(ray.Z, ray.X)
	if angle < 0 then angle = angle + (2 * math.pi) end
	angle = angle + math.pi
	if angle > 2 * math.pi then angle = angle - 2*math.pi end
	local direction = convertAngleToNSEW(angle)
	--print ("Direction from " .. pa.Name .. " to " .. pb.Name .. " is " .. direction)
	--print ("Angle between " .. pa.Name .. " and " .. pb.Name .. " is: " .. angle)
	local opos = pa.Position + Vector3.new(0, pa.Size.Y/2 + 0.4, 0)
	local newpos1, newpos2 = getCornersOnEdge(pb, direction)
	return createEdgeSpaces(newpos1, newpos2, 10, mark)
end

function findShortestJumpDistance(pa, pb, mark)
	local edgepoints_a = getEdgePoints(pa, pb, mark)
	local edgepoints_b = getEdgePoints(pb, pa, mark)
	local min_length = math.huge
	local mina, minb
	for _, edgepoint_a in pairs(edgepoints_a) do
		for _, edgepoint_b in pairs(edgepoints_b) do
			local length = (edgepoint_b - edgepoint_a).magnitude
			if length < min_length then
				mina = edgepoint_a
				minb = edgepoint_b
				min_length = length
			end
		end
	end
	return minb, mina
end

--findShortestJumpDistance(workspace.Ice.Part1, workspace.Ice.Part2)
--findShortestJumpDistance(workspace.Ice.Part2, workspace.Ice.Part1)
--findShortestJumpDistance(workspace.Ice.Part1, workspace.Ice.WestPart)
--findShortestJumpDistance(workspace.Ice.Part3, workspace.Ice.EastPart)

--findShortestJumpDistance(workspace.Ice.Part1, workspace.Ice.Part2)

--[[
findShortestJumpDistance(workspace.Stones.Part1, workspace.Stones.Part2)
findShortestJumpDistance(workspace.Stones.Part2, workspace.Stones.Part3)
findShortestJumpDistance(workspace.Stones.Part3, workspace.Stones.Part4)
findShortestJumpDistance(workspace.Stones.Part4, workspace.Stones.Part5)

findShortestJumpDistance(workspace.Stones2.Part1, workspace.Stones2.Part2)
findShortestJumpDistance(workspace.Stones2.Part2, workspace.Stones2.Part3)
findShortestJumpDistance(workspace.Stones2.Part3, workspace.Stones2.Part4)
findShortestJumpDistance(workspace.Stones2.Part4, workspace.Stones2.Part5)

]]--

--local result = getNearestPlatforms(workspace.Stones2.Part2)
--print(#result)

print "AI Move script starting"
stick = workspace.GoalStickPart.Value

while true do
	wait()
	goToGoal3(stick, workspace.Field)
end

print "Done"
