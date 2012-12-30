(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Printf

(* Helper function to generate link tags *)
let link ?cl href text =
  match cl with
  |None -> <:html<<a href="$str:href$">$str:text$</a>&>>
  |Some cl -> <:html<<a class="$str:cl$" href="$str:href$">$str:text$</a>&>>

(* Convert a Date to a human-readable string.
 * TODO is there a nicer Core function for this? *)
let human_readable_date d =
  Core.Std.(sprintf "%d %s %d" d.Date.d (Month.to_string d.Date.m) d.Date.y)

(* Generate IDs for endpoints *)
module ID = struct
  let output p = sprintf "output-%s" p.Elements.Output.id
end

(* Generate URLs. This is a quick hack to adjust URLs on the basis of where
 * they are used. I'm sure something better will come along... *)
module URL = struct
  open Elements
  module Top = struct
    let person p = Person.(link (sprintf "people/%s.html" p.id) p.name)
    let project p = Project.(link (sprintf "projects/%s.html" p.id) p.name)
    let output o = link (sprintf "projects/%s.html#output-%s" (Project.get_project_for_output o.Output.id).Project.id o.Output.id)
  end
  module Cur = struct
    let person p = Person.(link (sprintf "%s.html" p.id) p.name)
    let project p = Project.(link (sprintf "%s.html" p.id) p.name)
    let output o = link (sprintf "%s.html#output-%s" (Project.get_project_for_output o.Output.id).Project.id o.Output.id)
  end
  module Sub1 = struct
    let person p = Person.(link (sprintf "../people/%s.html" p.id) p.name)
    let project p = Project.(link (sprintf "../projects/%s.html" p.id) p.name)
    let output o = link (sprintf "../projects/%s.html#output-%s" (Project.get_project_for_output o.Output.id).Project.id o.Output.id)
  end
end

(* CSS style we include for each page.
 * Note that this style is specialised to the CUCL web page style *)
let style =
<:html<
  <style>
  blockquote {
    margin-left: 10px;
    padding-left: 20px;
    width: 80%;
    color: #330000;
  } 
  div.changelog { width:80%; font-size:90%; }
  blockquote p { margin-left: 0;  }
  div.ocl p { width: 75%; min-width: 400px; }
  div.ocl a { color: #330099; } 
  .ocl-output {
   width: 75%;
   padding:.4em 0;
   margin:0 0 1em 0;
   border-bottom: 1px solid #cccccc;
  }
  .ocl-cogs span { padding-right:30px; background-size:20px; background: url(../cogs.png) no-repeat right center; }
  .ocl-print span { padding-right:30px; background-size:20px; background: url(../print.png) no-repeat right center; }
  .ocl-cloud span { padding-right:30px; background-size:20px; background: url(../cloud.png) no-repeat right center; }
  .ocl-group span { padding-right:30px; background-size:20px; background: url(../group.png) no-repeat right center; }
  .ocl-bullhorn span { padding-right:30px; background-size:20px; background: url(../bullhorn.png) no-repeat right center; }
  .ocl-asset span { padding-right:30px; background-size:20px; background: url(../wrench.png) no-repeat right center; }
  </style>
>>

(* Output a single page as a HTML.t and the standard boilerplate HTML *)
let one_page ~title ~body =
  <:html<<title>$str:title$</title>$style$<body>$body$</body>&>>

(* Generate the overall people web pages *)
let people =
  let open Elements in
  (* Output a short list of projects this person works on.
   * TODO figure out how to get rid of that space before the comma. *)
  let projects_to_html (ty,projects) =
    let to_html p = URL.Sub1.project p in
    let rec aux = function
      |[] -> <:html<&>>
      |[hd] -> to_html hd
      |hd::tl -> <:html<$to_html hd$, $aux tl$>>
    in
    <:html<<br/><i>$str:Project.string_of_project_type ty$:</i> $aux projects$>>
  in
  (* Output a listitem for a person. Break out projects by type. *)
  let person_to_html p =
    let open Person in
    let role = match p.role with |None -> "" |Some r -> ", " ^ r in
    let link = <:html<<b>$URL.Cur.person p$</b>$str:role$>> in
    let projects = List.map projects_to_html (Project.for_person p.Person.id) in
    <:html<<li>$link$$list:projects$</li>&>>
  in
  (* CL is special as it comes first, then external folk *)
  let of_cucl_org = List.map person_to_html Person.of_cucl in
  let of_other_orgs = List.map (fun (org, people) -> 
    <:html< 
      <h3>$str:Elements.Person.to_string org$</h3>
      <ul>$list:List.map person_to_html people$</ul>
    >>) Person.of_other in
  (* Aggregate all the organisation info now *)
  let orgs = <:html<
    <h2>University of Cambridge Computer Laboratory</h2>
    <ul>$list:of_cucl_org$</ul>
    <h2>External Collaborators</h2>
    $list:of_other_orgs$
    >> in
  (* And output the full people web page *)
  one_page ~title:"People" ~body:
  <:html<
  <h1 id="Members">Project Members</h1>
  <p>OCaml Labs is situated at the University of Cambridge Computer Laboratory, and collaborates with a wide variety of industrial partners, primarily <a href="#janestreet">Jane Street</a>, <a href="#horizon">Horizon</a> and <a href="#citrix">Citrix</a>.  We also work closely with <a href="#ocamlpro">OCamlPro</a> on community software projects, and maintain the <a href="http://ocaml.org">ocaml.org</a> machine infrastructure.</p>
   $orgs$
  <h2>Funding</h2>
  <a name="funding"></a>
  <p>OCaml Labs is primarily funded by <a href="http://janestreet.com">Jane Street</a> with a platform grant for the first three years.  It is also supported by <a href="http://www.xen.org/products/cloudxen.html">Citrix Systems R&amp;D</a>.  There are also several research grants associated with OCamlLabs:</p><ul>
 <li>RCUK <a href="http://www.horizon.ac.uk">Horizon Digital Economy Research</a> Hub grant, <a class="icon-external" href="http://gow.epsrc.ac.uk/NGBOViewGrant.aspx?GrantRef=EP/G065802/1">EP/G065802/1</a>.</li>
 <li>EU FP7 <a href="http://trilogy2.eu">Trilogy2</a> project.</li>
  </ul>

  <p><img class="left" src="../images/janest.jpg" /><img width="150px" src="../images/citrix.gif"/></p>
>>

(* Generate a profile page per-person *)
let one_person p =
  let open Elements in
  let open Person in
  let role = match p.role with |None -> "" |Some r -> ", " ^ r in
  let homepage = match p.homepage with
   |None -> <:html< >>
   |Some h -> <:html< <p>$link h h$</p> >> in
  (* Generate a definition list of projects for this person, categorised by
   * the type of project *)
  let projects_to_html (ty,ps) =
    let ents = List.map (fun p ->
      <:html<<dd>$URL.Sub1.project p$</dd>&>>) ps in
    <:html<
      <dt>$str:Project.string_of_project_type ty$</dt>
      $list:ents$>> in
  let projects = List.map projects_to_html (Project.for_person p.id) in
  let body = <:html<
    <h1>$str:p.name$</h1>
    <p><b>$str:to_string p.affiliation$</b>$str:role$</p>
    $homepage$
    <div class="menu-wrapper">
    <dl class="menu">
    $list:projects$
    </dl>
    </div>
  >> in
  one_page ~title:p.name ~body

(* Convert a reference into a standalone HTML chunk *)
let ref_to_html r =
  let open Elements.Reference in
  match r.link with
  |None -> <:html< $str:r.name$ >>
  |Some (`Pdf url) -> link ~cl:"icon-pdf" url r.name
  |Some (`Blog url) -> link url r.name 
  |Some (`Github (user,repo)) -> link (sprintf "http://github.com/%s/%s" user repo) r.name 
  |Some (`Github_tag (user,repo,tag)) ->
    let url = sprintf "https://github.com/%s/%s/archive/%s.tar.gz" user repo tag in
    link url r.name
  |Some (`Webpage url) -> link url r.name
  |Some (`Video url) -> link ~cl:"icon-video" url r.name
  |Some (`Slideshare url) -> link url r.name
  |Some (`Paper (url,authors,descr)) ->
    let href = link ~cl:"icon-pdf" url r.name in
    <:html<$href$, <i>$str:authors$</i>, $str:descr$>>
  |Some (`Mantis id) ->
    let url = sprintf "http://caml.inria.fr/mantis/view.php?id=%d" id in 
    link url r.name

(* Short update, suitable for activity streams *)
let update_to_short_html outputfn u =
  let open Elements in
  let o = Update.output_of_update u in
  let icon, blurb = 
    match u.Update.ty, o.Output.ty with 
    |`Published _,`Paper _ -> "pdf", <:html<Published >>
    |`Published _,`Blog_post -> "rss", <:html<Blogged >>
    |`Published _,`Article _ -> "rss", <:html<Article >>
    |`Draft _,`Paper _ -> "pdf", <:html<Draft >>
    |`Draft _,`Blog_post -> "rss", <:html<Draft >>
    |`Draft _,`Article _ -> "rss", <:html<Draft >>
    |`Accepted _,`Paper _ -> "pdf", <:html<Paper accepted >>
    |`Event _,`Talk _ -> "video", <:html<Talk on >>
    |`Event _,`Asset -> "media", <:html<Update >>
    |`Event _,`Event _ -> "community", <:html<Working on >>
    |`Event _,`Code -> "media", <:html<Hacking on >>
    |`Event _,`Paper _ -> "video", <:html<Presented on >>
    |`Press _,`Article _ -> "community", <:html<Press on >>
    |`Release (_,r), _ -> "follow", <:html<Released $ref_to_html r$ of >> 
    |_ -> failwith ("internal error: unexpected combination of update/output in " ^ o.Output.id)
  in let icon = "icon-"^icon in
  <:html< <li><a class="$str:icon$"></a><i>$str:human_readable_date u.Update.date$</i>: 
    $blurb$ $ref_to_html o.Output.ref$ <i>$outputfn o "(more)"$</i></li> >>

(* Generate a single project page *)
let one_project proj =
  let open Elements in
  (* Assemble each project entry *)
  let update_to_html u = Scanner.md_string_to_html
    (sprintf "*%s*: %s" (human_readable_date u.Update.date) u.Update.descr) in
  let wrap_quote out = <:html< <blockquote>$Scanner.md_string_to_html out.Output.descr$</blockquote> >> in
  let wrap_noquote out = Scanner.md_string_to_html out.Output.descr in
  let output_to_html out =
    let open Output in
    let updates = List.map update_to_html (Update.for_output proj.Project.id out.id) in
    let extra = if List.length out.extra = 0 then <:html< >> else begin
        let e = List.map (fun x -> <:html< <li>$ref_to_html x$</li> >>) out.extra in
        <:html< <ul>$list:e$</ul> >>
      end in
    let wrap_id ?(quote=false) cl intro =
      let descr = if quote then wrap_quote out else wrap_noquote out in
      let name = out.ref.Reference.name in
      <:html<
       <a name="$str:ID.output out$"></a>
       <h3 class="$str:"ocl-output "^cl$" id="$str:name$"><span>$str:name$</span></h3>
       <p>$intro$</p>
       $descr$
       $extra$
       <div>$list:updates$</div>
      >> in
    match out.ty with
    |`Paper pref -> wrap_id ~quote:true "ocl-print" <:html<Paper on $ref_to_html out.ref$ at $ref_to_html pref$ with this abstract:>>
    |`Blog_post -> wrap_id ~quote:true "ocl-cloud" <:html<Blog post on $ref_to_html out.ref$:>>
    |`Talk pref -> wrap_id ~quote:true "ocl-bullhorn" <:html<Talk on $ref_to_html out.ref$ at $ref_to_html pref$:>>
    |`Article pref -> wrap_id ~quote:true "ocl-file" <:html<Article on $ref_to_html out.ref$ at $ref_to_html pref$: >>
    |`Asset -> wrap_id "ocl-asset" <:html< >>
    |`Code -> wrap_id "ocl-cogs" <:html< >>
    |`Event ps -> wrap_id "ocl-group" <:html< >>
  in
  let all_outputs = Project.get_outputs proj.Project.id in
  let event_outputs = List.filter (fun o -> match o.Output.ty with |`Blog_post |`Article _|`Talk _|`Asset|`Event _ -> true |_->false) all_outputs in
  let code_outputs = List.filter (fun o -> match o.Output.ty with |`Code -> true |_->false) all_outputs in
  let publication_outputs = List.filter (fun o -> match o.Output.ty with |`Paper _ -> true |_->false) all_outputs in
  let event_outputs = List.map output_to_html event_outputs in
  let code_outputs = List.map output_to_html code_outputs in
  let publication_outputs = List.map output_to_html publication_outputs in
  let iff l h = if List.length l > 0 then <:html< <h2 id="$str:h$">$str:h$</h2> >> else <:html< >> in
  let recent =
    let r = List.map (update_to_short_html URL.Cur.output) (Update.get_recent proj.Project.id) in
    match List.length r with
    |0 -> <:html< >>
    |_ -> <:html< <h4 id="Recent Updates">Recent Updates</h4><ul class="compact">$list:r$</ul> >>
  in
  let team = List.map (fun mem ->
      let p = Person.get mem.Project.person in
      let role = match mem.Project.role with |"" -> "" |r -> ", " ^ r in
      <:html<  
        <li>$URL.Sub1.person p$$str:role$ ($str:mem.Project.since$)</li>
      >>
    ) (List.sort Project.cmp_team proj.Project.team) in
  let related = match proj.Project.related with
    |[] -> <:html< >> 
    |related ->
       let l = List.map (fun r -> <:html<<li>$ref_to_html r$</li>&>>) related in
       <:html<<h4 id="Related Work">Related Work</h4><ul>$list:l$</ul>&>>
  in
  <:html<
      <title>$str:proj.Project.name$</title>
      $style$
      <body>
      <div class="ucampas-toc right"></div>
      <div class="ocl">
        <h1 id="$str:proj.Project.name$">$str:proj.Project.name$</h1>
        $Scanner.md_file_to_html ["projects";proj.Project.id] "intro"$
        <h4 id="Team">Team</h4>
        <ul class="compact">$list:team$</ul>
        $related$
        $recent$
        $iff publication_outputs "Publications"$
        $list:publication_outputs$
        $iff event_outputs "Activity"$
        $list:event_outputs$
        $iff code_outputs "Source Code"$
        $list:code_outputs$
      </div>
      </body>
  >>

(* Generate the overall project page *)
let projects =
  let pname ty = List.map (fun proj -> <:html< <dd>$URL.Cur.project proj$</dd> >>) (Elements.Project.of_type ty) in
  <:html<
    <title>Projects</title>
    <body>
      <p>We are still defining a full set of projects for OCamlLabs, but
      here are some that we are working on immediately. 
      We are <a class="icon-community" href="collaboration.html">hiring</a>
      if you are interested in any of these. This list is also not intended to
      be exhaustive, and there is plenty of room for research and experimentation.</p>
      <p>If you are a Part-II or ACS student and want to hack on OCaml for your
      project, then there are several good ideas here. Get in touch with
      <a href="/~avsm2">Anil Madhavapeddy</a>, <a href="/~am21">Alan Mycroft</a>,
      <a href="/~iml1">Ian Leslie</a> or <a href="/~jac22">Jon Crowcroft</a>
      to discuss concrete projects.</p>

      <div class="menu-wrapper">
      <dl class="menu">
      <dt>OCaml Platform</dt>$list:pname `Platform$
      <dt>Compiler Research</dt>$list:pname `Compiler$
      </dl>
      <dl class="menu">
      <dt>Systems Research</dt>$list:pname `Systems$
      </dl>
      </div>
    </body>
  >>

(* Generate the activity stream page *)
let activity =
  (* For a month/year, look for any narrative and include that, and then output the
   * raw update stream *)
  let for_month date =
    let hr_date = Core.Std.(Date.(sprintf "%s %d" (Month.to_string (date.m)) date.y)) in
    match Elements.Update.for_month date with
    |[] -> <:html<&>>
    |ups ->
      (* Grab an intro if available *)
      let intro = Scanner.md_file_to_html 
        ["monthly"; Core.Std.Date.to_string_iso8601_basic date] "monthly" in
      (* Flatten updates into stream *)
      let ups = List.sort Elements.Update.cmp (List.flatten (List.map snd ups)) in
      let updates = List.map (update_to_short_html URL.Sub1.output) ups in
      <:html<
      <h2 id="$str:hr_date$">$str:hr_date$</h2>
      $intro$
      <ul class="compact">
      $list:updates$
      </ul>
      >>
  in
  (* Iterate over all months in 2013, 2012, 2011, 2010 *)
  let dates =
    let open Core.Std in
    List.map [2013;2012;2011;2010] ~f:(fun y ->
      List.map Month.all ~f:(fun m ->
        Date.create_exn ~y ~m ~d:1)
    )
    |! List.concat
    |! List.sort ~cmp:Date.compare
    |! List.rev
  in
  let monthlies = List.map for_month dates in
  let body = <:html<
    <p>The OCaml Labs staff work on research activities, but also maintain code and help with 
    community activities. This page lists recent activities ordered by date. Click on any of
    them to visit the project page and get more detail on what's going on.  If you want to
    know more or help out, feel free to <a href="../contact.html">get in touch</a> any time.</p>
    $list:monthlies$
  >> in
  one_page ~title:"Activity" ~body

(* No more quotations from this point, so we can open up Core.Std.
 * TODO fix this! https://github.com/mirage/ocaml-cow/issues/2 *)
open Core.Std
let output ?(subdirs=[]) name page =
  let dir = String.concat ~sep:"/" subdirs in
  Unix.mkdir_p dir;
  let fname = Filename.concat dir (sprintf "%s-b.html" name) in
  let buf = Cow.Html.to_string page in
  eprintf "Writing: %s (%d bytes)\n" fname (String.length buf);
  Out_channel.write_all fname buf

(* The uconfig files are used by ucampas to generate the various
 * menus, so dynamically generate them from our generated pages. *)
let output_uconfig ?(subdirs=[]) files =
  let dir = String.concat ~sep:"/" subdirs in
  Unix.mkdir_p dir;
  let fname = Filename.concat dir "uconfig.txt" in
  let buf = List.map files ~f:(fun x -> x^".html") |! String.concat ~sep:"," in
  Out_channel.write_all fname buf

let _ =
  let open Elements in
  let root = try Sys.argv.(1) with _ ->
    (Printf.eprintf "Usage: %s <output-dir>\n%!" Sys.argv.(0); exit 1) in
  output ~subdirs:[root;"people"] "index" people;
  output_uconfig ~subdirs:[root;"people"] 
    (List.map Person.all ~f:(fun p ->
      let file = String.lowercase p.Person.id in
      output ~subdirs:[root;"people"] file (one_person p);
      file
    ));
  output ~subdirs:[root;"projects"] "index" projects;
  output_uconfig ~subdirs:[root;"projects"]
   (List.map Project.projects ~f:(fun proj -> 
      let file = String.lowercase proj.Project.id in
      output ~subdirs:[root;"projects"] file (one_project proj);
      file
   ));
  output ~subdirs:[root;"activity"] "index" activity