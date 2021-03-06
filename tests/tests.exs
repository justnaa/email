Code.require_file "tests/helper.exs"
ExUnit.start

defmodule ConnectionTests do
  use ExUnit.Case, async: true

  test "Server is up" do
    message = Helper.server_is_up 
    assert message == "220 ESMTP Juliette's SMTP Server \n"
  end
end

defmodule CommandTests do
  use ExUnit.Case, async: true

  test "Invalid command" do
    message = Helper.connect_and_send "BAD COMMAND: BAD"
    assert message == "500 I don't know that\n"
  end

  test "HELO" do
    message = Helper.connect_and_send "HELO"
    assert message == "250 Hello\n"
  end

  test "MAIL FROM" do
    message = Helper.connect_and_send "MAIL FROM: <test@test.test>"
    assert message == "250 Ok\n"
  end

  test "RCPT TO" do
    message = Helper.connect_and_send "RCPT TO: <tester@test.test>"
    assert message == "250 Ok\n"
  end
end

defmodule DataTests do
  use ExUnit.Case, async: true

  test "Simple email from Wikipedia" do
    # source: https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol
    message = "
    From: Bob Example <bob@example.com>
    To: Alice Example <alice@example.com>
    Cc: theboss@example.com
    Date: Tue, 15 Jan 2008 16:02:43 -0500
    Subject: Test message

    Hello Alice.
    This is a test message with 5 header fields and 4 lines in the message body.
    Your friend,
    Bob
    \r\n.\r\n
    "
    Helper.connect_and_send_data message

    contents = Helper.get_contents_of_newest_email 

    assert message == contents 
  end

  test "Email with emojis" do
    message = "
    From: Tests <tests@test> 
    To: Tests <test@test> 
    Subject: Test message

    Hello!
    😀😔😩🏳️‍🌈🏳
    \r\n.\r\n
    "
    Helper.connect_and_send_data message

    contents = Helper.get_contents_of_newest_email 

    assert message == contents 
  end

  test "Email with non-english characters" do
    message = "
    From: Tests <tests@test> 
    To: Tests <test@test> 
    Subject: Test message

    Bonjour!
    Comme ça va? é à û.
    \r\n.\r\n
    "
    Helper.connect_and_send_data message

    contents = Helper.get_contents_of_newest_email 

    assert message == contents 

  end
end

defmodule TriggerKill do
  use ExUnit.Case, async: true

  test "SIGPIPE code 13" do
      # SIGPIPE is triggered when a process writes to a pipe without an active connection on the other side.
    {:ok, socket} = :gen_tcp.connect('localhost', 2525, [:binary, active: false])
    {:ok, _} = :gen_tcp.recv(socket, 0)
    :gen_tcp.send(socket, "HELO")
    :gen_tcp.close socket
    # Now checking if server is still up
    message = Helper.server_is_up 
    assert message == "220 ESMTP Juliette's SMTP Server \n"
  end
end

