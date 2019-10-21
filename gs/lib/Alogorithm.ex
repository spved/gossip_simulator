defmodule GossipSimulator.Algorithm do
  use GenServer

  def startAlgorithm(algorithm,allNodes, startTime) do
    case algorithm do
      "gossip" -> startGossip(allNodes, startTime)
      "push-sum" ->startPushSum(allNodes, startTime)
    end
  end

  def startGossip(allNodes, startTime) do
    chosenFirstNode = Enum.random(allNodes)
    #updateCountState(chosenFirstNode, startTime, length(allNodes))
    GenServer.cast(chosenFirstNode, {:recurseGossip,startTime, 0.9*length(allNodes)})

  end

  def startPushSum(allNodes, startTime) do
    chosenFirstNode = Enum.random(allNodes)
    GenServer.cast(chosenFirstNode, {:ReceivePushSum,0,0,startTime, 0.8*length(allNodes)})
  end

  def sendPushSum(randomNode, myS, myW,startTime, total_nodes) do
    GenServer.cast(randomNode, {:ReceivePushSum,myS,myW,startTime, total_nodes})
  end

  def updatePIDState(pid,nodeID) do
    GenServer.call(pid, {:UpdatePIDState,nodeID})
  end

  def updateAdjacentListState(pid,map) do
    GenServer.call(pid, {:UpdateAdjacentState,map})
  end

  def getCountState(pid) do
  GenServer.call(pid,{:GetCountState})
  end

  def receiveMessage(pid, startTime, total) do
    GenServer.cast(pid, {:recurseGossip,startTime, total})
  end

  def getAdjacentList(pid) do
    GenServer.call(pid,{:GetAdjacentList})
  end

  def handle_cast({:recurseGossip,startTime, total},state) do
    {index,count,adjList,w} = state
    myCount = count + 1
    state = {index,myCount, adjList,w}
    #IO.inspect count, label: index
    cond do
      myCount < 11 ->
        adjacentList = adjList
        chosenRandomAdjacent=Enum.random(adjacentList)
        receiveMessage(chosenRandomAdjacent, startTime, total)
        GenServer.cast(self(), {:recurseGossip,startTime, total})
      true ->
        count = :ets.update_counter(:table, "count", {2,1})
        #IO.inspect count
        if(count >= total) do
          endTime = System.monotonic_time(:millisecond) - startTime
          IO.puts "Convergence achieved in = #{endTime} Milliseconds"
          System.halt(1)
        end
        Process.exit(self(), :normal)
    end
    {:noreply,state}
  end

  def handle_cast({:ReceivePushSum,incomingS,incomingW,startTime, total_nodes},state) do

    {s,pscount,adjList,w} = state
    myS = s + incomingS
    myW = w + incomingW

    difference = abs((myS/myW) - (s/w))
    if(difference < :math.pow(10,-10) && pscount==2) ||
    do
      count = :ets.update_counter(:table, "count", {2,1})
      if count >= total_nodes do
        endTime = System.monotonic_time(:millisecond) - startTime
        IO.puts "Convergence achieved in = " <> Integer.to_string(endTime) <>" Milliseconds"
        System.halt(1)
      end
      IO.inspect self(), label: "Killed"
      Process.exit(self(), :normal)
    end

    pscount = if(difference <= :math.pow(10,-10) && pscount<2) do
       pscount + 1
      else
        0
    end

    state = {myS/2,pscount,adjList,myW/2}
    randomNode = Enum.random(adjList)
    list = [myS, myW, difference, randomNode, pscount]
    IO.inspect(list)
    sendPushSum(randomNode, myS/2, myW/2,startTime, total_nodes)
    :timer.sleep(100)
    GenServer.cast(self(), {:ReceivePushSum,0,0,startTime, total_nodes})

    {:noreply,state}

  end

  def handle_cast({:SendSelfPushSum, s, w, startTime, total_nodes} ,state) do
    GenServer.cast(self(), {:receivPushSum,s,w,startTime,total_nodes})
    {:noreply, state}
  end

  def handle_cast({:receivPushSum,s,w,en,to},state) do
    {:noreply, state}
  end

  def handle_call({:UpdatePIDState,nodeID}, _from ,state) do
    {a,b,c,d} = state
    state={nodeID,b,c,d}
    {:reply,a, state}
  end

  def handle_call({:UpdateAdjacentState,map}, _from, state) do
    {a,b,_,d}=state
    state={a,b,map,d}
    {:reply,a, state}
  end

  def handle_call({:GetCountState}, _from ,state) do
    {_,b,_,_}=state
    {:reply,b, state}
  end

  def handle_call({:GetAdjacentList}, _from ,state) do
    {_,_,c,_}=state
    {:reply,c, state}
  end

  def init(:ok) do
    {:ok, {0,0,[],1}}
  end

  def start_node() do
    {:ok,pid}=GenServer.start_link(__MODULE__, :ok,[])
    pid
  end

end
