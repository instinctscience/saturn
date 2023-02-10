defmodule SaturnTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
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
          | total_time: System.convert_time_unit(12_345, :millisecond, :native)
        },
        metadata: %{
          @default_metadata
          | query: "SELECT * FROM users WHERE id = 5;",
            stacktrace: [
              {Saturn.Foobar, :do_thing, 3, file: "saturn/foobar.ex", line: 26},
              {Saturn, :foobar, 2, [file: "saturn.ex", line: 10]}
            ]
        }
      )
    end

    test "with no arguments orders queries by count" do
      report = capture_io(fn -> Saturn.report() end)

      assert """
             Query: "SELECT * FROM users;"
             Count: 2
             Stacktrace:
               saturn.ex:5: Saturn.fake/1

             Query: "SELECT * FROM users WHERE id = 5;"
             Count: 1
             Stacktrace:
               saturn/foobar.ex:26: Saturn.Foobar.do_thing/3
               saturn.ex:10: Saturn.foobar/2
             """ == report
    end

    test "can order by queries by time" do
      report = capture_io(fn -> Saturn.report(:time) end)

      assert """
             Query: "SELECT * FROM users;"
             Time: 246912 ms
             Stacktrace:
               saturn.ex:5: Saturn.fake/1

             Query: "SELECT * FROM users WHERE id = 5;"
             Time: 12345 ms
             Stacktrace:
               saturn/foobar.ex:26: Saturn.Foobar.do_thing/3
               saturn.ex:10: Saturn.foobar/2
             """ == report
    end

    test "can provide 'prof' style output" do
      report = capture_io(fn -> Saturn.report(:prof) end)

      assert """
             Source                                                                   Count %Count     Time %Time
             Saturn.fake/1                                                                2     66   246.91    95
               SELECT * FROM users;                                                       2     66   246.91    95
             Saturn.foobar/2                                                              1     33    12.35     4
               Saturn.Foobar.do_thing/3                                                   1     33    12.35     4
                 SELECT * FROM users WHERE id = 5;                                        1     33    12.35     4
             """ == report
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
