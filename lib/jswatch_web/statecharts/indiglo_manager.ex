defmodule JswatchWeb.IndigloManager do
  use GenServer

  def init(ui) do
    :gproc.reg({:p, :l, :ui_event})
    {:ok, %{ui_pid: ui, st: IndigloOff, count: 0}}
  end

  def handle_info(:"top-right-pressed", %{st: IndigloOff, ui_pid: ui} = state) do
    GenServer.cast(ui, :set_indiglo)
    {:noreply, state |> Map.put(:st, IndigloOn)}
  end

  def handle_info(:"top-right-released", %{st: IndigloOn, ui_pid: ui} = state) do
    GenServer.cast(ui, :unset_indiglo)
    {:noreply, state |> Map.put(:st, IndigloOff)}
  end

  def handle_info(:start_alarm, %{st: IndigloOff, ui_pid: ui} = state) do
    GenServer.cast(ui, :set_indiglo)
    Process.send_after(self(), AlarmOn_AlarmOff, 500)
    {:noreply, %{state | st: AlarmOn, count: 0}}
  end

  def handle_info(AlarmOn_AlarmOff, %{st: AlarmOn, ui_pid: ui, count: count} = state) do
    GenServer.cast(ui, :unset_indiglo)
    count = count + 1
    Process.send_after(self(), AlarmOff_AlarmOn, 500)
    {:noreply, %{state | st: AlarmOff, count: count}}
  end

  def handle_info(AlarmOff_AlarmOn, %{st: AlarmOff, ui_pid: ui, count: count} = state) do
    GenServer.cast(ui, :set_indiglo)
    count = count + 1
    if (count == 10) do
      GenServer.cast(ui, :unset_indiglo)
      {:noreply, %{state | st: IndigloOff, count: count}}
    else
      Process.send_after(self(), AlarmOn_AlarmOff, 500)
      {:noreply, %{state | st: AlarmOn, count: count}}
    end
  end

  def handle_info(:"top-right-pressed", %{ui_pid: ui} =state) do
    GenServer.cast{ui, :toggle_alarm}
    {:noreply, state}
  end

  def handle_info(_event, state), do: {:noreply, state}
end
