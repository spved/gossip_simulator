defmodule GossipSimulator do

  def main(args) do
    if (Enum.count(args)!=3) do
      IO.puts" Illegal Arguments Provided"
      System.halt(1)
    else
        numNodes=Enum.at(args, 0)|>String.to_integer()

        topology=Enum.at(args, 1)
        algorithm=Enum.at(args, 2)

        numNodes = if topology == "rand2D" || topology == "honeycomb" || topology == "randhoneycomb" do
           GossipSimulator.Topology.getNextPerfectSq(numNodes)
         else
           numNodes
         end
         numNodes = if topology == "3Dtorus" do
          GossipSimulator.Topology.getNextPerfectCube(numNodes)
        else
          numNodes
        end

        allNodes = Enum.map((1..numNodes), fn(x) ->
          pid=GossipSimulator.Algorithm.start_node()
          GossipSimulator.Algorithm.updatePIDState(pid, x)
          pid
        end)

        #IO.inspect numNodes
        table = :ets.new(:table, [:named_table,:public])
        :ets.insert(table, {"count",0})

        GossipSimulator.Topology.buildTopology(topology,allNodes)

        startTime = System.monotonic_time(:millisecond)

        GossipSimulator.Algorithm.startAlgorithm(algorithm, allNodes, startTime)
        infiniteLoop()
    end
  end
  def infiniteLoop() do
    infiniteLoop()
  end

end

GossipSimulator.main(System.argv())
