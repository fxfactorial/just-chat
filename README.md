This is a chat application on the local network. No configuration
needed, just type 

`node client.js`

and start typing. Anyone else that also does 
`node client.js` 

will be able to talk as well.

This works by sending multicasting messages over UDP.

# Etc Written in OCaml, compiled to JS.

To actually compile this project you'll need my `ocaml-nodejs`
bindings.
