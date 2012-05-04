%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2012 Basho Technologies, Inc.  All Rights Reserved.
%%
%% -------------------------------------------------------------------
-module(riak_cs_dtrace).

-export([dtrace/1]).

-define(MAGIC, '**DTRACE*SUPPORT**').

%% timing:
%%
%% f(Xs), begin [_|Xs] = [begin put('**DYNTRACE', undefined), timer:tc(riak_cs_dtrace, dtrace, [[42]]) end || _ <- lists:seq(1,10000)], lists:sum([X || {X, _} <- Xs]) / (length(Xs)-1) end.
%% -> 0.21024204840968194

dtrace(ArgList) ->
    case get(?MAGIC) of
        undefined ->
            case application:get_env(riak_moss, dtrace_support) of
                {ok, true} ->
                    case string:to_float(erlang:system_info(version)) of
                        {5.8, _} ->
                            %% R14B04
                            put(?MAGIC, dtrace),
                            dtrace(ArgList);
                        {Num, _} when Num > 5.8 ->
                            %% R15B or higher, though dyntrace option
                            %% was first available in R15B01.
                            put(?MAGIC, dyntrace),
                            dtrace(ArgList);
                        _ ->
                            put(?MAGIC, unsupported),
                            false
                    end;
                _ ->
                    put(?MAGIC, unsupported),
                    false
            end;
        dyntrace ->
            erlang:apply(dyntrace, p, ArgList);
        dtrace ->
            erlang:apply(dtrace, p, ArgList);
        _ ->
            false
    end.
