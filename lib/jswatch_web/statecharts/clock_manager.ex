defmodule JswatchWeb.ClockManager do
  use GenServer

  def init(ui) do
    :gproc.reg({:p, :l, :ui_event})
    {_, now} = :calendar.local_time()

    # alarm = Time.add(Time.from_erl!(now), 60)
    Process.send_after(self(), :working_working, 1000)
    {:ok, %{ui_pid: ui, time: Time.from_erl!(now), st1: Working, st2: Idle, mode: Time, alarm: ~T[12:00:00], count: 0, show: true, selection: Hour, timer: nil, alarmIcon: false}}
  end

  def handle_info(:working_working, %{ui_pid: ui, time: time, st1: Working, mode: mode, alarm: alarm, alarmIcon: alarmIcon} = state) do
    Process.send_after(self(), :working_working, 1000)
    time = Time.add(time, 1)
    if mode == Time do
      GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string })
    else if mode == EditingAlarm  do
      IO.puts("editing alarm")
      GenServer.cast(ui, {:set_time_display, alarm |> Time.truncate(:second) |> Time.to_string})
    end
    end
    if time == alarm && alarmIcon == true do
      :gproc.send({:p, :l, :ui_event}, :start_alarm)
    end
    {:noreply, state |> Map.put(:time, time) }
  end

  #Edit Clock
  def handle_info(:"bottom-right-pressed", %{st2: Idle, mode: Time, timer: timer} = state) do
    IO.puts("BTP")
    timer = :timer.send_after(1500, self(), :Editing)
    {:noreply, %{state | st2: Waiting, timer: timer}}
  end

  def handle_info(:"bottom-right-released", %{st2: Waiting, mode: Time, timer: timer} = state) do
    IO.puts("BTR")
    :timer.cancel(timer)
    {:noreply, %{state | st2: Idle, timer: nil}}
  end

  def handle_info(:Editing, %{st2: Waiting, mode: mode, ui_pid: ui} = state) do
    IO.puts(":Editing")
    mode = Editing
    Process.send_after(self(), Editing_to_Editing, 250)
    {:noreply,  %{state | st2: Editing, mode: mode}}
  end

  def handle_info(Editing_to_Editing, %{st2: Editing, mode: mode, ui_pid: ui, count: count, show: show, selection: selection} = state) do
    IO.puts("EditingToEditing")
    if (count == 20) do
      mode = Time
      {:noreply,  %{state | st2: Idle, mode: mode, count: 0}}
    else
      Process.send_after(self(), Editing_to_Editing, 250)
      count = count + 1
      show = !show
      form = format(state)
      GenServer.cast(ui, {:set_time_display, form})
      {:noreply,  %{state | st2: Editing, count: count, show: show, selection: selection}}
    end
  end

  def format(%{st2: Editing ,time: time, show: show, selection: selection} = state) do
    hora = time.hour
    minuto = time.minute
    segundo = time.second
    case selection do
      Hour -> "#{if show, do: hora, else: "  "}:#{minuto}:#{segundo}"
      Minute -> "#{hora}:#{if show, do: minuto, else: "  "}:#{segundo}"
      Second -> "#{hora}:#{minuto}:#{if show, do: segundo, else: "  "}"
    end
  end

  def handle_info(:"bottom-left-pressed", %{st2: Editing, mode: Editing, show: show, timer: timer, count: count} = state) do
    IO.puts("Editing BottomLeftPressed")
    show = true
    timer = :timer.send_after(300, self(), :increasing_to_increasing)
    {:noreply, %{state | st2: Increasing, show: show, timer: timer, count: 0}}
  end

  def handle_info(:"bottom-left-released", %{st2: Increasing, mode: Editing, selection: selection, time: time, ui_pid: ui, count: count, show: show} = state) do
    IO.puts("Editing BottomLeftReleased")

      if (selection == Hour) do
        time = Time.add(time, 1, :hour)
        GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string})
        {:noreply, %{state | st2: Editing, count: 0, time: time, selection: selection, show: true}}
      else if (selection == Minute) do
        time = Time.add(time, 1, :minute)
        GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string})
        {:noreply, %{state | st2: Editing, count: 0, time: time, selection: selection, show: true}}
      else if (selection == Second)do
        time = Time.add(time, 1, :second)
        GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string})
        {:noreply, %{state | st2: Editing, count: 0, time: time, selection: selection, show: true}}
      end
      end
      end


  end

  def handle_info(:increasing_to_increasing, %{st2: Increasing, mode: Editing, selection: selection, time: time, ui_pid: ui, count: count, timer: timer, show: show}= state) do
    IO.puts("Editing increasing to increasing")
    timer = :timer.send_after(300, self(), :increasing_to_increasing)

    if (selection == Hour) do
      time = Time.add(time, 1, :hour)
      GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string})
      {:noreply, %{state | st2: Increasing, time: time, timer: timer, count: 0, selection: selection, show: true}}
    else if (selection == Minute) do
      time = Time.add(time, 1, :minute)
      GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string})
      {:noreply, %{state | st2: Increasing, time: time, timer: timer, count: 0, selection: selection, show: true}}
    else if (selection == Second)do
      time = Time.add(time, 1, :second)
      GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string})
      {:noreply, %{state | st2: Increasing, time: time, timer: timer, count: 0, selection: selection, show: true}}
    end
    end
    end

  end

  def handle_info(:"bottom-right-pressed", %{st2: Editing, mode: Editing, selection: selection, show: show, count: count} = state) do
    if (selection == Hour) do
      {:noreply, %{state | st2: Editing, selection: Minute, show: true, count: 0}}
    else if (selection == Minute) do
      {:noreply, %{state | st2: Editing, selection: Second, show: true, count: 0}}
    else if (selection == Second)do
      {:noreply, %{state | st2: Editing, selection: Hour, show: true, count: 0}}
    end
  end
  end


end

  #### Edit Alarm ####
  def handle_info(:"bottom-left-pressed", %{st2: Idle, mode: Time, timer: timer, ui_pid: ui, alarmIcon: alarmIcon} = state) do
    IO.puts("BLP")

    timer = :timer.send_after(2000, self(), :EditingAlarm)
    GenServer.cast(ui, :toggle_alarm)
    alarmIcon = !alarmIcon
    {:noreply, %{state | st2: WaitingAlarm, timer: timer, alarmIcon: alarmIcon}}
  end

  def handle_info(:"bottom-left-released", %{st2: WaitingAlarm, mode: mode, timer: timer} = state) do
    IO.puts("BLR")
    :timer.cancel(timer)
    {:noreply, %{state | st2: WaitingAlarm, timer: nil}}
  end

  def handle_info(:EditingAlarm, %{st2: WaitingAlarm, mode: mode, ui_pid: ui, alarm: alarm} = state) do
    IO.puts(":EditingAlarm")
    Process.send_after(self(), EditingA_to_EditingA, 250)
    {:noreply,  %{state | st2: EditingAlarm, mode: EditingAlarm}}
  end

  def handle_info(EditingA_to_EditingA, %{st2: EditingAlarm, mode: mode, ui_pid: ui, count: count, show: show, selection: selection} = state) do
    IO.puts("EditingAToEditinA")
    if (count == 20) do
      mode = Time
      {:noreply,  %{state | st2: Idle, mode: mode, count: 0}}
    else
      Process.send_after(self(), EditingA_to_EditingA, 250)
      count = count + 1
      show = !show
      form = format(state)
      GenServer.cast(ui, {:set_time_display, form})
      {:noreply,  %{state | st2: EditingAlarm, count: count, show: show, selection: selection}}
    end
  end

  def format(%{st2: EditingAlarm, alarm: alarm, show: show, selection: selection} = state) do
    hora = alarm.hour
    minuto = alarm.minute
    segundo = alarm.second
    case selection do
      Hour -> "#{if show, do: hora, else: "  "}:#{minuto}:#{segundo}"
      Minute -> "#{hora}:#{if show, do: minuto, else: "  "}:#{segundo}"
      Second -> "#{hora}:#{minuto}:#{if show, do: segundo, else: "  "}"
    end
  end

  def handle_info(:"bottom-left-pressed", %{st2: EditingAlarm, mode: EditingAlarm, show: show, timer: timer, count: count} = state) do
    IO.puts("Editing BottomLeftPressed")
    show = true
    timer = :timer.send_after(300, self(), :increasinga_to_increasinga)
    {:noreply, %{state | st2: IncreasingAlarm, show: show, timer: timer, count: 0}}
  end

  def handle_info(:"bottom-left-released", %{st2: IncreasingAlarm, mode: EditingAlarm, selection: selection, alarm: alarm, ui_pid: ui, count: count, show: show} = state) do
    IO.puts("Editing BottomLeftReleased")

      if (selection == Hour) do
        alarm = Time.add(alarm, 1, :hour)
        GenServer.cast(ui, {:set_time_display, Time.truncate(alarm, :second) |> Time.to_string})
        {:noreply, %{state | st2: EditingAlarm, count: 0, alarm: alarm, selection: selection, show: true}}
      else if (selection == Minute) do
        alarm = Time.add(alarm, 1, :minute)
        GenServer.cast(ui, {:set_time_display, Time.truncate(alarm, :second) |> Time.to_string})
        {:noreply, %{state | st2: EditingAlarm, count: 0, alarm: alarm, selection: selection, show: true}}
      else if (selection == Second)do
        alarm = Time.add(alarm, 1, :second)
        GenServer.cast(ui, {:set_time_display, Time.truncate(alarm, :second) |> Time.to_string})
        {:noreply, %{state | st2: EditingAlarm, count: 0, alarm: alarm, selection: selection, show: true}}
      end
      end
      end


  end

  def handle_info(:increasinga_to_increasinga, %{st2: IncreasingAlarm, mode: EditingAlarm, selection: selection, alarm: alarm, ui_pid: ui, count: count, timer: timer, show: show}= state) do
    IO.puts("Editing increasing to increasing")
    timer = :timer.send_after(300, self(), :increasinga_to_increasinga)

    if (selection == Hour) do
      alarm = Time.add(alarm, 1, :hour)
      GenServer.cast(ui, {:set_time_display, Time.truncate(alarm, :second) |> Time.to_string})
      {:noreply, %{state | st2: IncreasingAlarm, alarm: alarm, timer: timer, count: 0, selection: selection, show: true}}
    else if (selection == Minute) do
      alarm = Time.add(alarm, 1, :minute)
      GenServer.cast(ui, {:set_time_display, Time.truncate(alarm, :second) |> Time.to_string})
      {:noreply, %{state | st2: IncreasingAlarm, alarm: alarm, timer: timer, count: 0, selection: selection, show: true}}
    else if (selection == Second) do
      alarm = Time.add(alarm, 1, :second)
      GenServer.cast(ui, {:set_time_display, Time.truncate(alarm, :second) |> Time.to_string})
      {:noreply, %{state | st2: IncreasingAlarm, alarm: alarm, timer: timer, count: 0, selection: selection, show: true}}
    end
    end
    end

  end

  def handle_info(:"bottom-right-pressed", %{st2: EditingAlarm, mode: EditingAlarm, selection: selection, show: show, count: count} = state) do
    if (selection == Hour) do
      {:noreply, %{state | st2: EditingAlarm, selection: Minute, show: true, count: 0}}
    else if (selection == Minute) do
      {:noreply, %{state | st2: EditingAlarm, selection: Second, show: true, count: 0}}
    else if (selection == Second)do
      {:noreply, %{state | st2: EditingAlarm, selection: Hour, show: true, count: 0}}
    end
  end
  end

end

  def handle_info(event, state) do
    IO.inspect(event)
    {:noreply, state}
  end
end
