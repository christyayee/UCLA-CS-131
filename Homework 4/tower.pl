% -------------------------------- tower helper predicates --------------------------------

basic_row_and_col_restrictions(GridSize,RowOrCol) :-
    length(RowOrCol,GridSize), % each list in T is of length N
    fd_domain(RowOrCol,1,GridSize), % each list in T contains integers from 1 to N
    fd_all_different(RowOrCol). % each list in T contains distinct integers

/* rules to check tower counts */

check_forward([],[]).

check_forward([LeftHead|LeftTail],[CurrRow|OtherRows]) :-
    tower_count(CurrRow,0,LeftHead),
    check_forward(LeftTail,OtherRows).

check_backward(Right,T) :-
    maplist(reverse,T,RevT),
    check_forward(Right,RevT).

/* end rules to check tower counts */


/* rules to find number of visible towers */

tower_count([],_,0).

tower_count([Front|Back],MaxHeight,NumVisible) :-
    Front #> MaxHeight,
    NumVisMinusOne #= NumVisible - 1,
    tower_count(Back,Front,NumVisMinusOne),!.

tower_count([Front|Back],MaxHeight,NumVisible) :-
    Front #< MaxHeight,
    tower_count(Back,MaxHeight,NumVisible),!.

/* end rules to find number of visible towers */


% -------------------------------- tower --------------------------------

tower(N,T,C) :-
    N >= 0, % N is a nonnegative integer
    length(T,N), % T must contain N lists

    maplist(basic_row_and_col_restrictions(N),T), % impose basic restrictions upon the rows
    transpose(T,T_transpose),
    maplist(basic_row_and_col_restrictions(N),T_transpose), % impose basic restrictions upon the columns

    maplist(fd_labeling,T),
    maplist(fd_labeling,T_transpose),

    C = counts(Top,Bottom,Left,Right), % check the counts on the edges
    check_forward(Left,T),
    check_backward(Right,T),
    check_forward(Top,T_transpose),
    check_backward(Bottom,T_transpose).


% -------------------------------- plain_tower helper predicates --------------------------------

unique_decreasing_list([],0).

unique_decreasing_list([H|T],N) :-
    H = N,
    N_decremented is N - 1,
    unique_decreasing_list(T,N_decremented).


plain_check_count(UniqueList,N,RowOrCol,CountElement) :-
    permutation(UniqueList,RowOrCol),
    between(1,N,CountElement),
    plain_tower_count(RowOrCol,0,CountElement).


/* rules to find number of visible towers */

plain_tower_count([],_,0).

plain_tower_count([Front|Back],MaxHeight,NumVisible) :-
    Front > MaxHeight,
    NumVisMinusOne is NumVisible - 1,
    plain_tower_count(Back,Front,NumVisMinusOne).

plain_tower_count([Front|Back],MaxHeight,NumVisible) :-
    Front < MaxHeight,
    plain_tower_count(Back,MaxHeight,NumVisible).

/* end rules to find number of visible towers */


% -------------------------------- plain_tower --------------------------------

plain_tower(N,T,C) :-
    N >= 0,
    length(T,N),

    length(UniqueList,N),
    unique_decreasing_list(UniqueList,N), % basic unique list, ex: [4,3,2,1]

    C = counts(Top,Bottom,Left,Right),
    length(Left,N),
    length(Right,N),
    length(Top,N),
    length(Bottom,N),

    maplist(plain_check_count(UniqueList,N),T,Left),

    maplist(reverse,T,RevT),

    maplist(plain_check_count(UniqueList,N),RevT,Right),

    transpose(T,T_transpose),

    maplist(plain_check_count(UniqueList,N),T_transpose,Top),

    maplist(reverse,T_transpose,RevT_transpose),

    maplist(plain_check_count(UniqueList,N),RevT_transpose,Bottom).


% -------------------------------- matrix transposition helper predicate --------------------------------

/* stack overflow matrix transposition implementation */

% transpose implementation taken from https://stackoverflow.com/questions/4280986/how-to-transpose-a-matrix-in-prolog
transpose([], []).

transpose([F|Fs], Ts) :-
    transpose(F, [F|Fs], Ts).

transpose([], _, []).
transpose([_|Rs], Ms, [Ts|Tss]) :-
    lists_firsts_rests(Ms, Ts, Ms1),
    transpose(Rs, Ms1, Tss).

lists_firsts_rests([], [], []).
lists_firsts_rests([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-
    lists_firsts_rests(Rest, Fs, Oss).

/* end stack overflow matrix transposition implementation */

/*
% my own implementation of transpose(X,Y) that is sadly not as efficient as the one on stack overflow

% true if the 2nd parameter contains the heads of all of the lists that the 1st parameter contains
get_all_list_heads([],[]).
get_all_list_heads([[FirstListHead|_]|OtherLists], [FirstHead|OtherHeads]) :-
    FirstListHead = FirstHead,
    get_all_list_heads(OtherLists,OtherHeads).

% true if the 2nd parameter contains the tails of all of the lists that the 1st parameter contains
get_all_list_tails([],[]).
get_all_list_tails([[_|FirstListTail]|OtherLists],[FirstTail|OtherTails]) :-
    FirstListTail = FirstTail,
    get_all_list_tails(OtherLists,OtherTails).

emptyList([]).

% this case is necessary because the last recursive call for transpose
% will look something like the following: transpose([[],[]],[])
transpose(X,[]) :-
    maplist(emptyList,X),!. % included a cut because it kept asking for more results

transpose(X,[Y_head|Y_tail]) :-
    get_all_list_heads(X,X_heads),
    X_heads = Y_head,
    get_all_list_tails(X,X_tails),
    transpose(X_tails,Y_tail).
*/
