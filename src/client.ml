open Nodejs

module U = Yojson.Basic.Util

let (multicast_addr, bind_addr, port) = "224.1.1.1", "0.0.0.0", 6811

let () =
  Random.self_init ();
  let p = new process in
  let user_name = ref (Printf.sprintf "User:%d" (Random.int 10000)) in
  let listener = Udp_datagram.(create_socket ~reuse_address:true Udp4) in
  let sender = Udp_datagram.(create_socket ~reuse_address:true Udp4) in

  listener#bind ~port ~address:multicast_addr ~f:begin fun () ->
    listener#add_membership multicast_addr;
    listener#set_broadcast true;
    listener#set_multicast_loopback true
  end ();

  listener#on_message begin fun b resp ->

    let handle = b#to_string () |> json_of_string in
    if (handle <!> "id" |> Js.to_string) <> !user_name
    then print_string (handle <!> "message" |> Js.to_string)

  end;

  p#stdin#on_data begin function
    | String _ -> ()
    | Buffer b ->
      let msg = b#to_string () in
      (* This needs to be redone with Re_pcre *)
      if String.length msg > 10 then begin
        let modify = String.sub msg 0 9 in
        if modify = "set name:"
        then begin
          let as_string = Js.string (String.trim msg) in
          let chopped =
            as_string##split (Js.string ":") |> to_string_list |> Array.of_list
          in
          user_name := chopped.(1)
        end
      end;

      let msg = Printf.sprintf "%s>>>%s" !user_name (b#to_string ()) in
      let total_message = (object%js
        val id = !user_name |> to_js_str
        val message = msg |> to_js_str
        end) |> stringify
      in
      sender#send
        ~offset:0
        ~length:(String.length total_message)
        ~port
        ~dest_address:multicast_addr
        (String total_message)
    end
