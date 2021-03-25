defmodule Sidekick.Job do
  @moduledoc """
  Internal structure to represent a async job task,
  as well as functions to help manage them.
  """

  @enforce_keys [:ref, :status, :result]
  defstruct [:job_alias | @enforce_keys]

  @type status :: :running | :complete | :failed

  @type t :: %__MODULE__{
          job_alias: String.t() | nil,
          ref: reference(),
          status: status(),
          result: any()
        }

  @spec change_status(list(t()), status(), reference(), any()) :: list(t())
  def change_status(jobs, status, ref, result) do
    jobs
    |> Enum.map(fn
      job when job.ref == ref -> %{job | status: status, result: result}
      job -> job
    end)
  end

  @spec format_jobs(list(t())) :: list({String.t(), status(), String.t()})
  def format_jobs(jobs) do
    Enum.map(jobs, &{&1.job_alias, &1.status, &1.result})
  end
end
