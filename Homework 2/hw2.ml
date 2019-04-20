type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(*
type nonterminals =
  | Sentence | Noun | NP | Verb | Adjective | Adverb

let rules =
  [Sentence, [N NP; N Verb; N NP];
   Sentence, [N NP; N Verb];
   NP, [N Adjective; N Noun];
   NP, [N Noun];
   Noun, [T"apple"];
   Noun, [T"Paul"; T"Eggert"];
   Verb, [T"love"];
   Adjective, [T"crispy"]]
  *)

type awksub_nonterminals =
  | Expr | Term | Lvalue | Incrop | Binop | Num

let awksub_rules =
   [Expr, [N Term; N Binop; N Expr];
    Expr, [N Term];
    Term, [N Num];
    Term, [N Lvalue];
    Term, [N Incrop; N Lvalue];
    Term, [N Lvalue; N Incrop];
    Term, [T"("; N Expr; T")"];
    Lvalue, [T"$"; N Expr];
    Incrop, [T"++"];
    Incrop, [T"--"];
    Binop, [T"+"];
    Binop, [T"-"];
    Num, [T"0"];
    Num, [T"1"];
    Num, [T"2"];
    Num, [T"3"];
    Num, [T"4"];
    Num, [T"5"];
    Num, [T"6"];
    Num, [T"7"];
    Num, [T"8"];
    Num, [T"9"]]

let gram =
  (Expr,
   function
     | Expr ->
         [[N Term; N Binop; N Expr];
          [N Term]]
     | Term ->
	 [[N Num];
	  [N Lvalue];
	  [N Incrop; N Lvalue];
	  [N Lvalue; N Incrop];
	  [T"("; N Expr; T")"]]
     | Lvalue ->
	 [[T"$"; N Expr]]
     | Incrop ->
	 [[T"++"];
	  [T"--"]]
     | Binop ->
	 [[T"+"];
	  [T"-"]]
     | Num ->
	 [[T"0"]; [T"1"]; [T"2"]; [T"3"]; [T"4"];
	  [T"5"]; [T"6"]; [T"7"]; [T"8"]; [T"9"]])

(*
type nonterms =
  | PHRASE | NOUN | VERB 

let kimmogram = 
  (PHRASE,
   function
     | PHRASE -> [[N NOUN; N VERB]]
     | NOUN -> [[T "mary"];[T "mark"]]
     | VERB -> [[T "eats"];[T "drinks"]])

let kimmofrag = ["mark"; "eats"; "pizza"]

let kimaccept = function 
  | "pizza"::t -> Some ("pizza"::t) 
  | _ -> None


*)


(* function that takes in a NT value and returns its alternative list *)
let productionFunc listOfRules nontermVal =
	let matchingRules = List.filter (fun rule -> (fst rule) = nontermVal) listOfRules in
	List.map (fun (first, second) -> second) matchingRules (* remove the LHS from each rule, thus returning an alternative list *)

(* converts hw1 style grammar to hw2 style grammar *)
let convert_grammar gram1 = 
	let startSymbol = (fst gram1) and
	listOfRules = (snd gram1) in
	(startSymbol, productionFunc listOfRules)


type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal



let rec parse_tree_leaves = function
  | Leaf terminalSymbol -> [terminalSymbol]
  | Node (_, childrenHead::childrenTail) -> (parse_tree_leaves childrenHead) @ (parse_node_children childrenTail)
  | _ -> []
and parse_node_children = function
  | [] -> []
  | (h::t) -> (parse_tree_leaves h) @ (parse_node_children t)







(*

let start = Expr
let prodFunc = snd gram
let frag = ["9"; "+"; "$"; "1"; "+"]

let accept_all string = Some string

let altList = prodFunc start (* [[N Term; N Binop; N Expr]; [N Term]] *)
*)

let rec parse_alternative_list prodFunc startSymbol altList accept frag =
  match altList with
  | [] -> None (* we've exhausted all the rules and didn't find a match *)
  | (firstRule::otherRules) ->
    let resultOfParseRule = parse_rule prodFunc firstRule accept frag in
    match resultOfParseRule with
    | None -> parse_alternative_list prodFunc startSymbol otherRules accept frag (* try the next rule *)
    | Some x -> Some x

and parse_rule prodFunc currRule accept frag =
  match currRule with
  | [] -> accept frag (* we've matched up all the symbols of the rule *)
  | (firstSymbol::otherSymbols) ->
    match firstSymbol with
    | (N nonterminalSym) ->
      let curriedAcceptor = parse_rule prodFunc otherSymbols accept in
      parse_alternative_list prodFunc nonterminalSym (prodFunc nonterminalSym) curriedAcceptor frag
    | (T terminalSym) ->
      match frag with
      | [] -> None (* found a symbol with no symbols left in the fragment to match it, so backtrack *)
      | (fragHead::fragTail) ->
        match (terminalSym = fragHead) with
        | true -> parse_rule prodFunc otherSymbols accept fragTail (* found a match, now check rest of frag *)
        | false -> None (* backtrack *)

let make_matcher gram =
  let startSymbol = (fst gram)
  and prodFunc = (snd gram) in
  let altList = (prodFunc startSymbol) in
  (fun accept frag -> parse_alternative_list prodFunc startSymbol altList accept frag)

let parse_tree_acceptor frag tree =
  match frag with
  | [] -> Some tree
  | _ -> None

let rec parse_alternative_list_tree prodFunc startSymbol altList accept frag treeChildren =
  match altList with 
  | [] -> None (* we've exhausted all the rules and didn't find a parse tree *)
  | (firstRule::otherRules) ->
    let resultOfParseRuleTree = parse_rule_tree prodFunc startSymbol firstRule accept frag treeChildren in
    match resultOfParseRuleTree with
    | None -> parse_alternative_list_tree prodFunc startSymbol otherRules accept frag treeChildren (* try the next rule *)
    | Some x -> Some x




and parse_rule_tree prodFunc startSymbol currRule accept frag treeChildren =
  match currRule with
  | [] -> accept frag (Node(startSymbol, treeChildren))
  | (firstSymbol::otherSymbols) ->
    match firstSymbol with
    | (N nonterminalSym) ->
      (* let curriedAcceptor = parse_rule_tree prodFunc startSymbol otherSymbols accept in *)

      let curriedAcceptor frag2 tree2 =
        parse_rule_tree prodFunc startSymbol otherSymbols accept frag2 (treeChildren @ [tree2]) in
      
      parse_alternative_list_tree prodFunc nonterminalSym (prodFunc nonterminalSym) curriedAcceptor frag []
      (* the [] should prob be replaced with the treeChildren itself *)
    | (T terminalSym) ->
      match frag with
      | [] -> None (* backtrack *)
      | (fragHead::fragTail) ->
        match (terminalSym = fragHead) with
        | true -> parse_rule_tree prodFunc startSymbol otherSymbols accept fragTail (treeChildren @ [Leaf terminalSym])
        | false -> None (* backtrack *)


let make_parser gram =
  let startSymbol = (fst gram)
  and prodFunc = (snd gram) in
  let altList = (prodFunc startSymbol) in
  (fun frag -> parse_alternative_list_tree prodFunc startSymbol altList parse_tree_acceptor frag [])





type nonterms = 
| PHRASE | NOUN

let g = 
  (PHRASE,
   function
     | PHRASE -> [[N NOUN]]
     | NOUN -> [[T "mark"]])

let f = ["mark"]

let startSymbol = PHRASE
let prodFunc = snd g
let altList = prodFunc startSymbol




