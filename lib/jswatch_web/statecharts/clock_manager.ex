defmodule JswatchWeb.ClockManager do
  use GenServer

  def init(ui) do
    :gproc.reg({:p, :l, :ui_event})
    {_, now} = :calendar.local_time()

    alarm = Time.add(Time.from_erl!(now), 10)

    Process.send_after(self(), :working_working, 1000)
    {:ok, %{ui_pid: ui, time: Time.from_erl!(now), st: Working, mode: Time, alarm: alarm}}
  end

  def handle_info(:working_working, %{ui_pid: ui, time: time, st: Working, mode: mode, alarm: alarm} = state) do
    Process.send_after(self(), :working_working, 1000)
    time = Time.add(time, 1)
    if mode == Time do
      GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string })
    end
    if time == alarm do
      :gproc.send({:p, :l, :ui_event}, :start_alarm)
    end
    {:noreply, state |> Map.put(:time, time) }
  end

  def handle_info(:"top-left-pressed", %{ui_pid: ui} = state) do
    GenServer.cast(ui, :toggle_alarm)
    {:noreply, state}
  end

  def handle_info(event, state) do
    IO.inspect(event)
    {:noreply, state}
  end
end
