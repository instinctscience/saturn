defmodule SaturnTest do
  use ExUnit.Case, async: false
  doctest Saturn

  @default_measurements %{total_time: System.convert_time_unit(123_456, :millisecond, :native)}
  @default_metadata %{
    query: "SELECT * FROM users;",
    stacktrace: [{Saturn, :fake, 1, [file: "saturn.ex", line: 5]}]
  }

  setup_all do
    :ok =
      :telemetry.attach(
        "saturn-aggregator",
        [:test, :repo, :query],
        &Saturn.handle_query/4,
        nil
      )
  end

  setup do
    Saturn.clear()
    Saturn.enable()
  end

  describe "disable" do
    test "does not track queries when disabled" do
      Saturn.disable()

      send_query()

      %{queries: queries} = :sys.get_state(Saturn.Aggregator)

      assert queries == %{}
    end
  end

  describe "enable" do
    test "tracks queries when enabled" do
      Saturn.enable()

      send_query()

      %{queries: queries} = :sys.get_state(Saturn.Aggregator)

      assert Enum.count(queries) == 1
    end
  end

  describe "report" do
    setup do
      send_query()
      send_query()

      send_query(
        measurements: %{
          @default_measurements
          | total_time: System.convert_time_unit(12_345_678, :millisecond, :native)
        },
        metadata: %{
          @default_metadata
          | query: "SELECT * FROM users WHERE id = 5;",
            stacktrace: [
              {Saturn, :foobar, 2, [file: "saturn.ex", line: 10]},
              {Saturn.Foobar, :do_thing, 3, file: "saturn/foobar.ex", line: 26}
            ]
        }
      )
    end

    test "with no arguments orders queries by count" do
      report = Saturn.report()

      assert {:ok,
              [
                {%{query: "SELECT * FROM users;"}, 2},
                {%{query: "SELECT * FROM users WHERE id = 5;"}, 1}
              ]} = report
    end

    test "can order by queries by time" do
      report = Saturn.report(:time)

      assert {:ok,
              [
                {%{query: "SELECT * FROM users WHERE id = 5;"}, 12_345_678},
                {%{query: "SELECT * FROM users;"}, 246_912}
              ]} = report
    end

    test "can provide 'prof' style output" do
      report = Saturn.report(:prof)

      assert {:ok,
              """
              Function                                                      Count %Count %Time
              Saturn.fake/1                                                     2     66     1
                SELECT * FROM users;                                            2     66     1
              Saturn.foobar/2                                                   1     33    98
                Saturn.Foobar.do_thing/3                                        1     33    98
                  SELECT * FROM users WHERE id = 5;                             1     33    98\
              """} == report
    end
  end

  defp send_query(overrides \\ []) do
    measurements = Keyword.get(overrides, :measurements, @default_measurements)
    metadata = Keyword.get(overrides, :metadata, @default_metadata)

    :telemetry.execute(
      [:test, :repo, :query],
      measurements,
      metadata
    )
  end
end
