defmodule Sidekick do
  @moduledoc """
  A process that can spawn tasks asynchronously.
  """

  use GenServer

  alias Sidekick.Job

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @spec spawn_job(mfa(), String.t()) :: {:ok, String.t()}
  def spawn_job({m, f, a}, job_alias) do
    GenServer.cast(__MODULE__, {:spawn_job, {m, f, a}, job_alias})
    {:ok, job_alias}
  end

  @spec status() :: {String.t(), Job.status(), String.t()}
  def status() do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:spawn_job, {module, function, args}, job_alias}, jobs) do
    %Task{ref: ref} =
      Task.Supervisor.async_nolink(Sidekick.TaskSupervisor, fn ->
        Kernel.apply(module, function, args)
      end)

    {:noreply,
     [
       %Sidekick.Job{
         job_alias: job_alias,
         ref: ref,
         status: :running,
         result: "--"
       }
       | jobs
     ]}
  end

  @impl true
  def handle_call(:status, _from, jobs) do
    {:reply, Job.format_jobs(jobs), jobs}
  end

  @impl true
  def handle_info({ref, result}, jobs) when is_reference(ref) do
    {:noreply, Job.change_status(jobs, :complete, ref, result)}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, jobs) when reason != :normal do
    {:noreply, Job.change_status(jobs, :failed, ref, reason)}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, jobs) do
    {:noreply, jobs}
  end
end
