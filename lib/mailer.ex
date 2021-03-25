defmodule Mailer do
  def send_email(from, to, body) do
    :timer.sleep(1_000)
    IO.inspect("Sent mail from #{from} to #{to}:\n\n#{body}")
    # uncomment to simulate failure
    # 0 / 0
    :done
  end
end
