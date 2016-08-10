gen_bunny
---------

gen_bunny is a RabbitMQ_ client library for erlang whose primary goal is to be
easy to use.  Especially for simple publisher and consumer applications.

.. image:: https://secure.travis-ci.org/dreid/gen_bunny.png?branch=master
   :target: http://travis-ci.org/dreid/gen_bunny


Getting the code
================

One of gen_bunny's goals is to make it as easy to get all the required code
build it, and start using it as possible.  To achieve this goal we've used
rebar_ for dependency management, as our build tool, and as our test runner.

To get a local copy of gen_bunny only the following steps are needed.

::

  git clone http://github.com/dreid/gen_bunny.git
  cd gen_bunny
  make
  make test

Getting Started
===============

After cloning and compiling the code as above, start two terminal sessions
(in tabs, or with screen or tmux). Start RabbitMQ in the first session:

::

  rabbitmq-server

In the second terminal, start an erlang shell:

::

  erl -pa `find . -type d -name ebin`
  %% Load Records Used With Rabbit:
  > rr("deps/rabbit_common/include/rabbit_framing.hrl").

  %% Start gen_bunny as a producer using the default exchange:
  > bunnyc:start_link(mq_producer,
                      {network, "localhost", 5672, {<<"guest">>, <<"guest">>}, <<"/">>},
                      {#'exchange.declare'{exchange = <<"">>, durable=true}},
                      [] ).

  %% Start another gen_bunny as a producer/consumer using a named queue and exchange:
  > bunnyc:start_link(mq_consumer, {network, "localhost"}, {<<"myexchange">>, <<"myqueue">>, <<"">>}, []).

  %% Publish a message to "myqueue" via the default exchange:
  > bunnyc:publish(mq_producer, <<"myqueue">>, <<"hello, world">>).

  %% Fetch the message:
  > bunnyc:get(mq_consumer, true).

  {#'basic.get_ok'{delivery_tag = 1,redelivered = false,
                   exchange = <<>>,routing_key = <<"myqueue">>,
                   message_count = 0},
   {amqp_msg,#'P_basic'{content_type = undefined,
                        content_encoding = undefined,headers = undefined,
                        delivery_mode = undefined,priority = undefined,
                        correlation_id = undefined,reply_to = undefined,
                        expiration = undefined,message_id = undefined,
                        timestamp = undefined,type = undefined,user_id = undefined,
                        app_id = undefined,cluster_id = undefined},
             <<"hello, world">>}}

  %% Publish a message to "myqueue" via the "myexchange" exchange:
  > bunnyc:publish(mq_consumer, <<"">>, <<"hello again">>).

  %% Fetch the message:
  > bunnyc:get(mq_consumer, true).

  {#'basic.get_ok'{delivery_tag = 2,redelivered = false,
                   exchange = <<"myexchange">>,routing_key = <<>>,
                   message_count = 0},
   {amqp_msg,#'P_basic'{content_type = undefined,
                        content_encoding = undefined,headers = undefined,
                        delivery_mode = undefined,priority = undefined,
                        correlation_id = undefined,reply_to = undefined,
                        expiration = undefined,message_id = undefined,
                        timestamp = undefined,type = undefined,user_id = undefined,
                        app_id = undefined,cluster_id = undefined},
             <<"hello again">>}}

  %% Shut it down:
  > bunnyc:stop(mq_consumer).
  > bunnyc:stop(mq_producer).


Using rebar
===========

Using rebar_ for dependency management means that gen_bunny can also be used as
a rebar_ dependency.  This is the preferred way to get gen_bunny into your
application, and in fact at this time the only supported way.

To depend on gen_bunny in your application simply add the following line to
your project's ``rebar.config`` file.

::

  {deps, [{gen_bunny, ".*",
           {git, "http://github.com/dreid/gen_bunny.git", ""}}]}.



After that simply using ``rebar get-deps compile`` will fetch the necessary
amqp_client and rabbit_common dependencies and build them along with gen_bunny.

.. _RabbitMQ: http://rabbitmq.com/
.. _rebar: http://hg.basho.com/rebar/wiki/Home
