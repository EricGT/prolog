/* Part of fileutils
	Copyright 2012-2015 Samer Abdallah (Queen Mary University of London; UCL)
	 
	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

:- module(dot,[
      dotrun/4
	,	graph_dot/2
	]).

/** <module> Graphviz language 
	
   Produces .dot language graphs from relational and functional schemata.

   Graph strucure is as follows:
   ==
   digraph  ---> digraph(Name:term, G:list(element)).
   subgraph ---> subgraph(Name:term, G:list(element)).
   element  ---> subgraph
               ; option
               ; node_opts(list(option))
               ; edge_opts(list(option))
               ; with_opts(element, list(option))
               ; arrow(term,term)   % directed edge
               ; line(term,term)    % undirected edge
               ; node(term).
   option   ---> opt_name=opt_value.
   opt_name  == atom
   opt_value == phrase
   ==
   Graph, node and edge labels can be terms and are written using write/1 for
   writing in the dot file.

   ---
   Samer Abdallah
   Centre for Digital Music, Queen Mary, University of London, 2007
   Department of Computer Science, UCL, 2014
 */

:- use_module(library(fileutils)).
:- use_module(library(dcg_core)).
:- use_module(library(dcg_codes)).
:- use_module(library(swipe)).

:- set_prolog_flag(double_quotes, codes).

digraph(Name,G) -->
	"digraph ", wr(Name), cr,
	dotblock([ overlap=at(false)
            , spline=at(true)
            , contentrate=at(true)
            | G]).

subgraph(Name,G) --> "subgraph ", wr(Name), cr, dotblock(G).

dotblock(L) --> brace(( cr, dotlist(L), cr)), cr.
dotline(L) --> "\t", L, ";\n".
dotlist([]) --> "".
dotlist([L|LS]) -->
	if(L=dotblock(B),
		dotblock(B),
		dotline(L)),
	dotlist(LS).


with_opts(A,Opts) --> phrase(A), " ", sqbr(optlist(Opts)).
optlist(L) --> seqmap_with_sep(",",call,L).

node_opts(Opts) --> with_opts(at(node), Opts).
edge_opts(Opts) --> with_opts(at(edge), Opts).
% nq(A)   --> wr(A).
node(A) --> qq(wr(A)).
arrow(A,B) --> node(A), " -> ", node(B).
line(A,B)  --> node(A), " -- ", node(B).
(A=B) --> at(A), "=", B.
	
swipe:def(unflatten(Opts), sh($dot >> $dot,'unflatten~s', [\OptCodes])):-
   phrase(seqmap(uopt,Opts),OptCodes).

swipe:def(graphviz(unflatten,Fmt), unflatten([]) >> graphviz(dot,Fmt)) :- !.
swipe:def(graphviz(unflatten(Opts),Fmt), unflatten(Opts) >> graphviz(dot,Fmt)) :- !.
swipe:def(graphviz(Meth,Fmt), sh($dot >> $Fmt, '~w~w -T~w', [\Meth,\Opts,\Fmt])):-
   member(Meth,[dot,neato,sfdp,fdp,circo,twopi]), !,
   must_be(oneof([svg,png,ps,eps,pdf]),Fmt),
   (Fmt=svg -> Opts=' -Gfontnames=svg'; Opts='').

uopt(c(N)) --> " -c", wr(N).
uopt(l(N)) --> " -l", wr(N).
uopt(fl(N)) --> " -f", uopt(l(N)).

%% dotrun( +Method:graphviz_method, +Fmt:atom, G:digraph, +File:atom) is det.
%
%  Method determines which GraphViz programs are used to render the graph:
%  ==
%  graphviz_method ---> dot ; neato; fdp ; sfdp ; circo ; twopi
%                     ; unflatten
%                     ; unflatten(list(unflatten_opt)).
%  unflatten_opt   ---> l(N:natural)   % -l<N> 
%                     ; fl(N:natural)  % -f -l<N>
%                     ; c(natural).    % -c<N> 
%  ==
%  The unflatten method attempts to alleviate the problem of very wide graphs,
%  and implies that dot is used to render the graph. The default option list is empty.
%
%  Fmt can be any format supported by Graphviz under the -T option, including
%  ps, eps, pdf, svg, png.
%
%  See man page for unflatten for more information.
%  TODO: Could add more options for dot.
dotrun(Meth,Fmt,Graph,File) :-
   with_pipe_input(S, graphviz(Meth,Fmt) >: File^Fmt, with_output_to(S,writedcg(Graph))).


%% graph_dot( +G:digraph, +File:atom) is det.
graph_dot(Graph,File) :-
	with_output_to_file(File,writedcg(Graph)).

%%% Options

% Graph options
dotopt(graph,[size,page,ratio,margin,nodesep,ranksep,ordering,rankdir,
	pagedir,rank,rotate,center,nslimit,mclimit,layers,color,href,splines,
	start,epsilon,root,overlap, mindist,'K',maxiter]).


% Node options
dotopt(node, [label,fontsize,fontname,shape,color,fillcolor,fontcolor,style,
	layer,regular,peripheries,sides,orientation,distortion,skew,href,target,
	tooltip,root,pin]).

% Edge options
dotopt(edge, [minlen,weight,label,fontsize,fontname,fontcolor,style,color,
		dir,tailclip,headclip,href,target,tooltip,arrowhead,arrowtail,
		headlabel,taillabel,labeldistance,port_label_distance,decorate,
		samehead,sametail,constraint,layer,w,len]).


% Node options values
dotopt(node, label, A) :- ground(A).
dotopt(node, fontsize, N) :- between(1,256,N). % arbitrary maximum!
dotopt(node, fontname, A) :- ground(A).
dotopt(node, shape,
	[	plaintext,ellipse,box,circle,egg,triangle,diamond,
		trapezium,parallelogram,house,hexagon,octagon]).
dotopt(node, style, [filled,solid,dashed,dotted,bold,invis]).


% Edge options values
dotopt(edge, fontsize, N) :- between(1,256,N). % arbitrary maximum!
dotopt(edge, label, A) :- ground(A).
dotopt(node, fontname, A) :- ground(A).
dotopt(node, style, [solid,dashed,dotted,bold,invis]).
