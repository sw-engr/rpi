# rpi

This repository contains various posts that I have made to the My Head Stuck in the Computer blog.  To see them with their images go to the blog.

In particular, the posts of this repository are about my message delivery framework written in both C# and Ada.  This framework delivers messages within an application between components of the application where the components are meant to be standalone and not directly interface with other components.

The impetus was to have a C# application that mimics a long ago project send key selections of a pseudo CDU (Control Display Unit) of an aircraft to an Ada application acting as an extremely scaled down OFP (Operational Flight Program).  I had a much, much older version of the framework in Ada but not such that it would communicate with the C# version.  Therefore I am translating the C# version to Ada to have two compatible applications to remotely communicate and deliver messages.
