-module(twitter_client).
-export[initiate/0, user_input/2, sock_server_connection/1].

initiate() ->
    io:fwrite("\n************Welcome to Twitter**********\n"),
    PortNumber = 1204,
    IPAddress = "localhost",
    {ok, Sock} = gen_tcp:connect(IPAddress, PortNumber, [binary, {packet, 0}]),
    io:fwrite("\n Sending Connection Request to the Twitter Engine! \n"),
    spawn(twitter_client, user_input, [Sock, "_"]),
    sock_server_connection(Sock).

sock_server_connection(Sock) ->
    receive
        {tcp, Sock, Data} ->
            io:fwrite("Received Response!\n"),
            io:fwrite(Data),
            sock_server_connection(Sock);
        {tcp, closed, Sock} ->  
            io:fwrite("Client disconnected - Socket Breached!~n")
        end.

user_input(Sock, UserName) ->
    timer:sleep(1000),
    io:fwrite("\n1. signup         2. login\n"), 
    io:fwrite("\n3. tweet          4. re-tweet\n"),
    io:fwrite("\n5. follow         6. util\n"),
    io:fwrite("\n7. logout\n"),
    {ok, [Instruction]} = io:fread("\nEnter Input to perform following Action: ", "~s\n"),
    if 
        Instruction == "signup" ->
            UserName1 = signin_user(Sock);
        Instruction == "tweet" ->
            if
                UserName == "_" ->
                    io:fwrite("You have to signup first!\n"),
                    UserName1 = user_input(Sock, UserName);
                true ->
                    tweet_sent(Sock,UserName),
                    UserName1 = UserName
            end;
        Instruction == "re-tweet" ->
            if
                UserName == "_" ->
                    io:fwrite("You have to signup first!\n"),
                    UserName1 = user_input(Sock, UserName);
                true ->
                    re_tweet(Sock, UserName),
                    UserName1 = UserName
            end;
        Instruction == "follow" ->
            if
                UserName == "_" ->
                    io:fwrite("You have signup first!\n"),
                    UserName1 = user_input(Sock, UserName);
                true ->
                    follow(Sock, UserName),
                    UserName1 = UserName
            end;
        Instruction == "util" ->
            if
                UserName == "_" ->
                    io:fwrite("You have signup first!\n"),
                    UserName1 = user_input(Sock, UserName);
                true ->
                    query_tweet(Sock, UserName),
                    UserName1 = UserName
            end;
        Instruction == "logout" ->
            if
                UserName == "_" ->
                    io:fwrite("You have signup first!\n"),
                    UserName1 = user_input(Sock, UserName);
                true ->
                    UserName1 = "_"
            end;
        Instruction == "login" ->
            UserName1 = login_user();
        true ->
            io:fwrite("Invalid command!, Please Enter another command!\n"),
            UserName1 = user_input(Sock, UserName)
    end,
    user_input(Sock, UserName1).


signin_user(Sock) ->
    {ok, [UserName]} = io:fread("\nEnter the User Name: ", "~s\n"),
    io:format("SELF: ~p\n", [self()]),
    ok = gen_tcp:send(Sock, [["register", ",", UserName, ",", pid_to_list(self())]]),
    io:fwrite("\nAccount has been Registered\n"),
    UserName.

login_user() ->
    {ok, [UserName]} = io:fread("\nEnter the User Name: ", "~s\n"),
    io:format("SELF: ~p\n", [self()]),
    io:fwrite("\nAccount has been Signed in\n"),
    UserName.

tweet_sent(Sock,UserName) ->
    Tweet = io:get_line("\nTweet freely since now it's a free bird :"),
    ok = gen_tcp:send(Sock, ["tweet", "," ,UserName, ",", Tweet]),
    io:fwrite("\nTweet Sent !\n").

re_tweet(Socket, UserName) ->
    {ok, [Person_UserName]} = io:fread("\nEnter the Username whose tweet you want to re-tweet: ", "~s\n"),
    ok = gen_tcp:send(Socket, ["query", "," ,UserName, ",",  "3", ",", Person_UserName]),
    Tweet = io:get_line("\nEnter the tweet that you want to repost: "),
    ok = gen_tcp:send(Socket, ["retweet", "," ,Person_UserName, ",", UserName,",",Tweet]),
    io:fwrite("\nRetweeted\n").

follow(Sock, UserName) ->
    SubscribeUserName = io:get_line("\nWho do you want to subscribe to?:"),
    ok = gen_tcp:send(Sock, ["subscribe", "," ,UserName, ",", SubscribeUserName]),
    io:fwrite("\nSubscribed!\n").

query_tweet(Sock, UserName) ->
    io:fwrite("\n Querying Options:\n"),
    io:fwrite("\n 1. @MyMentions\n"),
    io:fwrite("\n 2. HashtagQuery\n"),
    io:fwrite("\n 3. Tweets of User\n"),
    {ok, [Option]} = io:fread("\nEnter the number of the required Functionality : ", "~s\n"),
    if
        Option == "1" ->
            ok = gen_tcp:send(Sock, ["query", "," ,UserName, ",", "1", ",", UserName]);
        Option == "2" ->
            {ok, [Hashtag]} = io:fread("\nEnter the HashTag to be searched: ", "~s\n"),
            ok = gen_tcp:send(Sock, ["query", "," ,UserName, ",","2",",", Hashtag]);
        true ->
            {ok, [Sub_UserName]} = io:fread("\nWhose tweets do you want? ", "~s\n"),
            ok = gen_tcp:send(Sock, ["query", "," ,UserName, ",", "3",",",Sub_UserName])
    end.