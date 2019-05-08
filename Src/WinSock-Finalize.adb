
separate( WinSock )

procedure Finalize is

begin -- Finalize

  -- Set the Receive_Index and Receive and Transmit Supported
  for I in 1..Comm.Count loop
--    IC := Comm.Data(IC).Receive_Index;
--check for Remote_Com below and check ???
    FindRemoteCom:
    for J in 1..Comm.Count loop
      if Comm.Data(J).Local_Com = Comm.Data(I).Local_Com and then
         Comm.Data(J).DeliveryId = 0 -- not set as yet set --Receive_Index = 0 
      then 
--      Local_Com := Comm.Data(I).Local_Com;
--      Comm.Data(I).Receive_Index := Comm.Data(I).Remote_Com; -- not the component
        for K in 1..Comm.Count loop
          if Comm.Data(J).Remote_Com = Comm.Data(K).Remote_Com then
            Comm.Link(I).Receive.Supported := True;
            Comm.Link(I).Transmit.Supported := True;
            Comm.Data(J).DeliveryId := --Receive_Index := 
              Component_Ids_Type(Comm.Data(K).Remote_Com); --J;
            exit FindRemoteCom; -- loop
          end if;
        end loop;
      end if;
    end loop FindRemoteCom;
  end loop;
--<<< what of the above is necessary?? what really is?

  -- Install threads for receive "components".
  for I in 1..Comm.Count loop
--    IC := Comm.Data(Connection_Count_Type(I)).Receive_Index;
 --   IC := I;
    Text_IO.Put("WinSock-Install Recv Index");
    Int_IO.Put(Integer(I));
    if Comm.Link(I).Transmit.Supported then
      Text_IO.Put_Line(" Transmit.Supported");
    else
      Text_IO.Put_Line(" ");
    end if;
    if Comm.Link(I).Transmit.Supported then
      Recv.Install( Id => I ); --IC ); 
      -- Install threads for transmit "component".
      Text_IO.Put("WinSock-Install Xmit Index");
      Int_IO.Put(Integer(I)); --C));
      Text_IO.Put_Line(" ");
      Xmit.Install( Id => I ); --C );
--      -- Create the socket for Transmit.
--      TransmitCreate( Index => IC );
    end if;
  end loop;

--      <<<    IC := Comm.Data(IC).Receive_Index;
--          Comm.Link(IC).Receive.Supported := True;
--          Comm.Link(IC).Transmit.Supported := True; --<<< only Link >>>
--          ItemAdded := True;

--          Comm.Count := Connection_Count_Type(Index);
--          Comm.Count := Comm.Count + 1;

end Finalize;
