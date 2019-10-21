defmodule GossipSimulator.Topology do

def buildTopology(topology,allNodes) do
    case topology do
      "full" ->buildFull(allNodes)
      "rand2D" ->buildRand2D(allNodes)
      "line" ->buildLine(allNodes)
      "3Dtorus" -> build3DTorus(allNodes)
      "honeycomb" ->buildHoneyComb(allNodes)
      "randhoneycomb" ->buildHoneyCombRandom(allNodes)
    end
  end

  def buildFull(allNodes) do
    Enum.each(allNodes, fn(k) ->
      adjList=List.delete(allNodes,k)
      GossipSimulator.Algorithm.updateAdjacentListState(k,adjList)
    end)
  end


  def getNextPerfectSq(numNodes) do
    round :math.pow(:math.ceil(:math.sqrt(numNodes)) ,2)
  end

  def buildRand2D(allNodes) do
    cDistance = 0.1
    #IO.puts("Building 2D Topology")
    numNodes=Enum.count allNodes
    side= Kernel.trunc(:math.sqrt numNodes)
    distanceFactor = 1/side
    coord = Enum.map(allNodes, fn(k) ->
      count=Enum.find_index(allNodes, fn(x) -> x==k end)
      x = rem(count, side)
      y = div(count, side)
      [k,x,y]
    end)
    #IO.inspect coord
    Enum.each(allNodes, fn(k) ->
      count=Enum.find_index(allNodes, fn(x) -> x==k end)
      x = rem(count, side)
      y = div(count, side)

      adjList = Enum.map(coord, fn(node) ->
        [pid, x1, y1] = node
        list = [x,y,x1,y1,distanceFactor]
        distance = :math.pow((x-x1)*distanceFactor, 2) + :math.pow((y-y1)*distanceFactor, 2)
        #IO.inspect list, label: distance
        if distance < cDistance do
          pid
        end
      end)
      adjList = Enum.filter(adjList, & !is_nil(&1))
      #IO.inspect(adjList)
      GossipSimulator.Algorithm.updateAdjacentListState(k,adjList)
    end)
  end

  def getNextPerfectCube(numNodes) do

    cube_root = nth_root(3, numNodes)
    rounded_cube_root = round(cube_root)
    rounded_cube = round(:math.pow(:math.ceil(rounded_cube_root) ,3))
    rounded_cube
  end

  def nth_root(n, x, precision \\ 1.0e-5) do
    f = fn(prev) -> ((n - 1) * prev + x / :math.pow(prev, (n-1))) / n end
    fixed_point(f, x, precision, f.(x))
  end

  defp fixed_point(_, guess, tolerance, next) when abs(guess - next) < tolerance, do: next
  defp fixed_point(f, _, tolerance, next), do: fixed_point(f, next, tolerance, f.(next))


  def build3DTorus(allNodes) do
    numNodes=Enum.count allNodes
    side = round(nth_root(3, numNodes))
    Enum.each(allNodes, fn(k) ->

      count=Enum.find_index(allNodes, fn(x) -> x==k end)
      index = if(!isNodeFrontPlane(count+1, side)) do
        count - 1
      else
        count + side - 1
      end
      neighbhourFront=Enum.fetch!(allNodes, index)

      index = if(!isNodeBackPlane(count+1, side)) do
        count + 1
      else
        count - side + 1
      end
      neighbhourBack=Enum.fetch!(allNodes, index)

      index = if(!isNodeLeftPlane(count+1, side)) do
        count - side
      else
        count + Kernel.trunc(:math.pow(side,2)) - side
      end
      neighbhourLeft=Enum.fetch!(allNodes, index)

      index = if(!isNodeRightPlane(count+1, side)) do
        count + side
      else
        count - Kernel.trunc(:math.pow(side,2)) + side
      end
      neighbhourRight=Enum.fetch!(allNodes, index)

      index = if(!isNodeBottomPlane(count+1, side)) do
        count + Kernel.trunc(:math.pow(side,2))
      else
        count - Kernel.trunc(:math.pow(side,3)) + Kernel.trunc(:math.pow(side,2))
      end
      neighbhourBottom=Enum.fetch!(allNodes, index)

      index = if(!isNodeTopPlane(count+1, side)) do
        count - Kernel.trunc(:math.pow(side,2))
      else
        count + Kernel.trunc(:math.pow(side,3)) - Kernel.trunc(:math.pow(side,2))
      end
      neighbhourTop=Enum.fetch!(allNodes, index)

      adjList=[neighbhourTop, neighbhourBottom, neighbhourLeft, neighbhourRight, neighbhourFront, neighbhourBack]
      GossipSimulator.Algorithm.updateAdjacentListState(k,adjList)
    end)
  end

  #####
  #functions to get 3D
  #####

  def isNodeTopPlane(index, side) do
    if index < :math.pow(side, 2) do
      true
    else
      false
    end
  end

  def isNodeBottomPlane(index, side) do
    size = :math.pow(side, 3) - :math.pow(side, 2)
    if index > size do
      true
    else
      false
    end
  end

  def isNodeFrontPlane(index, side) do
    if rem(index,side) == 1 do
      true
    else
      false
    end
  end

  def isNodeBackPlane(index, side) do
    if rem(index,side) == 0 do
      true
    else
      false
    end
  end

  def isNodeLeftPlane(index, side) do
    temp = rem(index, Kernel.trunc(:math.pow(side,2)))
    if temp <= side && temp > 0 do
      true
    else
      false
    end
  end

  def isNodeRightPlane(index, side) do
    temp = rem(index, Kernel.trunc(:math.pow(side,2)))
    if temp > (side - 1) * side || temp == 0 do
      true
    else
      false
    end
  end

  #####
  #End of 3D
  #####
  def buildLine(allNodes) do

    numNodes=Enum.count allNodes
    Enum.each(allNodes, fn(k) ->
      count=Enum.find_index(allNodes, fn(x) -> x==k end)

      cond do
        numNodes==count+1 ->
          neighbhour1=Enum.fetch!(allNodes, count - 1)
          neighbhour2=List.first (allNodes)
          adjList=[neighbhour1,neighbhour2]
          GossipSimulator.Algorithm.updateAdjacentListState(k,adjList)
        true ->
          neighbhour1=Enum.fetch!(allNodes, count + 1)
          neighbhour2=Enum.fetch!(allNodes, count - 1)
          adjList=[neighbhour1,neighbhour2]
          GossipSimulator.Algorithm.updateAdjacentListState(k,adjList)
      end

    end)
  end

  def buildHoneyComb(allNodes) do
    numNodes=Enum.count allNodes
    side= Kernel.trunc(:math.sqrt numNodes)
    Enum.each(allNodes, fn(k) ->
      count=Enum.find_index(allNodes, fn(x) -> x==k end)

      index = if(!isNodeBottom(count,numNodes)) do
        count + side
      else
        count - (side*side - side)
      end
      neighbhourBottom=Enum.fetch!(allNodes, index)

      index = if(!isNodeTop(count,numNodes)) do
        count - side
      else
        count + (side*side - side)
      end
      neighbhourTop=Enum.fetch!(allNodes, index)

      x = rem(count, side)
      y = div(count, side)

      index = if (isEven(x) && isEven(y)) || (!isEven(x) && !isEven(y)) do
        if (!isNodeLeft(count,numNodes)) do
          count - 1
        else
          count + side - 1
        end
      else
        if (!isNodeRight(count,numNodes)) do
          count + 1
        else
          count - side + 1
        end
      end

      neighbhourSide=Enum.fetch!(allNodes, index)
      adjList = [neighbhourBottom, neighbhourTop, neighbhourSide]

      GossipSimulator.Algorithm.updateAdjacentListState(k,adjList)

    end)
  end

  def buildHoneyCombRandom(allNodes) do
    numNodes=Enum.count allNodes
    side= Kernel.trunc(:math.sqrt numNodes)
    Enum.each(allNodes, fn(k) ->
      tempList=allNodes
      count=Enum.find_index(allNodes, fn(x) -> x==k end)

      index = if(!isNodeBottom(count,numNodes)) do
        count + side
      else
        count - (side*side - side)
      end
      neighbhourBottom=Enum.fetch!(allNodes, index)
      tempList=List.delete_at(tempList,index)

      index = if(!isNodeTop(count,numNodes)) do
        count - side
      else
        count + (side*side - side)
      end
      neighbhourTop=Enum.fetch!(allNodes, index)
      tempList=List.delete_at(tempList,index)

      x = rem(count, side)
      y = div(count, side)

      index = if (isEven(x) && isEven(y)) || (!isEven(x) && !isEven(y)) do
        if (!isNodeLeft(count,numNodes)) do
          count - 1
        else
          count + side - 1
        end
      else
        if (!isNodeRight(count,numNodes)) do
          count + 1
        else
          count - side + 1
        end
      end
      neighbhourSide = Enum.fetch!(allNodes, index)
      tempList = List.delete_at(tempList,index)

      neighbhourRandom = Enum.random(tempList)

      adjList = [neighbhourBottom, neighbhourTop, neighbhourSide, neighbhourRandom]
      GossipSimulator.Algorithm.updateAdjacentListState(k,adjList)

    end)
  end

  def isEven (num) do
    if rem(num,2)==0 do
      true
    else
      false
    end
  end

  ###
  # functions to get 2D grid
  ###
  def isNodeBottom(i,length) do
    if(i>=(length-(:math.sqrt length))) do
      true
    else
      false
    end
  end

  def isNodeTop(i,length) do
    if(i< :math.sqrt length) do
      true
    else
      false
    end
  end

  def isNodeLeft(i,length) do
    if(rem(i,round(:math.sqrt(length))) == 0) do
      true
    else
      false
    end
  end

  def isNodeRight(i,length) do
    if(rem(i + 1,round(:math.sqrt(length))) == 0) do
      true
    else
      false
    end
  end

  ####
  # End of 2D grid
  ####
end
