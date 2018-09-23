# Date: 2015-12-17; Title: News replaced with blog; Tags: blog,yaaf; Author: Matthias Dittrich

Just a short information that now the 'news' section has been replaced with a blog here on yaaf.de.
At the end of this post I show all the code needed to include a basic markdown based blog to your website via `FSharp.Formatting`!

Some more features will be added soon:

 - Ability to comment blog posts.
 - Ability to filter posts by year and tag.

The blog was build with the lovely [FSharp.Formatting](https://github.com/tpetricek/FSharp.Formatting/) library (the first time I actually used it as a regular library!).
It's a very simple in-memory implementation (which is fine for the low number of posts) and all posts are markup files in a folder which are processed to html by `FSharp.Formatting`.
I added some trickery to allow embedding of title, author, date and tags into the template file (basically I read the first headline and remove it from the parsed markup file).

A blog entry file looks like this:

```markdown
# Date: 2015-12-17; Title: News replaced with blog; Tags: blog,yaaf; Author: Matthias Dittrich

Just a short information that now the 'news' section has been replaced with a blog here on yaaf.de.
At the end of this post I show all the code needed to include a basic markdown based blog to your website via `FSharp.Formatting`!

Some more features will be added soon:

 - Ability to comment blog posts.
 - Ability to filter posts by year and tag.

... continue with markup ....
```

Of course while adding the blog I found a bug and [fixed it](https://github.com/tpetricek/FSharp.Formatting/pull/361)...
And because I was already at the FSF code I tried to help [ademar](https://github.com/ademar) with a PR which I want to merge a long time now: https://github.com/tpetricek/FSharp.Formatting/pull/331 (see [related PR](https://github.com/ademar/FSharp.Formatting/pull/1))


### Edit 2015-12-18:

Of course I had to update some css scripts such that blog post links are properly wrapped and the embedded code is as well.

The following css does the trick for links:

```css
#content .inbox a {
    /* Prevent Links from breaking the Layout (blogposts!) */
    display: inline-block;
    word-break: break-all;
}
```

The problem was that long automatically converted links would not wrap properly, so this tells the browser that I want to break links on every character.


Then I had to handle the regular pre tag (because I modified the FSF generation to be comaptible with [prismjs](http://prismjs.com/)):

```css
#content .inbox {
	/* basically the same as margin above, but helps with pre tags */
	max-width: calc(100% - 50px);
}
```

It's strange that the pre-tag seems to ignore the regular wrapping rule and must be forced to show the scroll-bar by setting the max-width property of the parent element.
I could see in the browser that the setup was correct as it was floating ok up to the point where it had to show the scroll-bars (and hide/wrap text).


The third problem had to do with the tables FSF is generating for F# scripts (for F# I still use the FSF defaults):

```css
/* Fix that F# code scrolls properly with the page (50px = 2 * Margin of the inbox) */
table.pre {
    table-layout: fixed;
    width: calc(100% - 50px);
}

table.pre pre {
  /* Show scrollbar when size is too small */
  overflow: auto;
}

table.pre td.lines {
  /* Align on top such that line numbers are at the correct place when the scrollbar is shown */
  vertical-align: top;
}
```

It seems to be the regular behavior that tables do not wrap out of the box, see [this](http://stackoverflow.com/questions/1258416/word-wrap-in-an-html-table).


And finally here is the box with some F# code to test the `css` changes (Note: this is all the code I used to process the markdown files to html via FSF):

    /// Simple in-memory database for my (quite limited number of) blogpost.
    namespace Yaaf.Website.Blog
    open System
    /// Html content of a post
    type Html = RawHtml of string
    /// The title of a post
    type Title = Title of string
    /// The stripped title of a post
    type StrippedTitle = StrippedTitle of string
    
    type Post =
      { Date : DateTime
        Title : Title
        Content : Html
        Teaser : Html
        TipsHtml : Html
        Tags : string list
        Author: string }
    
    open System.Collections.Generic
    type PostDb = IDictionary<DateTime * StrippedTitle, Post>
    
    module BlogDatabase =
      open System.IO
      open System.Web
      open FSharp.Markdown
      open FSharp.Literate
      
    
      let private formattingContext templateFile format generateAnchors replacements layoutRoots =
          { TemplateFile = templateFile 
            Replacements = defaultArg replacements []
            GenerateLineNumbers = true
            IncludeSource = false
            Prefix = "fs"
            OutputKind = defaultArg format OutputKind.Html
            GenerateHeaderAnchors = defaultArg generateAnchors false
            LayoutRoots = defaultArg layoutRoots [] }
    
      let rec private replaceCodeBlocks ctx = function
          | Matching.LiterateParagraph(special) -> 
              match special with
              | LanguageTaggedCode(lang, code) -> 
                  let inlined = 
                    match ctx.OutputKind with
                    | OutputKind.Html ->
                        let code = HttpUtility.HtmlEncode code
                        let codeHtmlKey = sprintf "language-%s" lang
                        sprintf "<pre class=\"line-numbers %s\"><code class=\"%s\">%s</code></pre>" codeHtmlKey codeHtmlKey code
                    | OutputKind.Latex ->
                        sprintf "\\begin{lstlisting}\n%s\n\\end{lstlisting}" code
                  Some(InlineBlock(inlined))
              | _ -> Some (EmbedParagraphs special)
          | Matching.ParagraphNested(pn, nested) ->
              let nested = List.map (List.choose (replaceCodeBlocks ctx)) nested
              Some(Matching.ParagraphNested(pn, nested))
          | par -> Some par
          
      let private editLiterateDocument ctx (doc:LiterateDocument) =
        doc.With(paragraphs = List.choose (replaceCodeBlocks ctx) doc.Paragraphs)
    
      let parseRawDate (rawDate:string) = DateTime.ParseExact(rawDate, "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture)
    
      let parseRawTitle (rawTitle:string) =
        // 2015-12-17: Testpost with some long title
        let splitString = " - "
        let firstColon = rawTitle.IndexOf(splitString)
        if firstColon < 0 then failwithf "invalid title (expected instance of ' - ' to split date from title): '%s'" rawTitle
        let rawDate = rawTitle.Substring(0, firstColon)
        let realTitle = rawTitle.Substring(firstColon + splitString.Length)
        Title (realTitle.Trim()), parseRawDate rawDate
    
      let parseHeaderLine (line:string) =
        let splitString = ": "
        let firstColon = line.IndexOf(splitString)
        if firstColon < 0 then failwithf "invalid header line (expected instance of ': ' to split header key from value): '%s'" line
        let rawKey = line.Substring(0, firstColon)
        let rawValue = line.Substring(firstColon + splitString.Length)
        rawKey, rawValue
    
    
      let extractHeading (doc:LiterateDocument) =
        let filtered, heading =
          doc.Paragraphs
          |> Seq.fold (fun (collected, oldHeading) item ->
            let takeItem, heading =
              match oldHeading, item with
              | None, (Heading(1, text)) ->
                let doc = MarkdownDocument([Span(text)], dict [])
                false, Some(Formatting.format doc false OutputKind.Html)
              | None, _ -> true, None
              | _ -> true, oldHeading
            (if takeItem then item :: collected else collected), heading) ([], None)
        heading, doc.With(paragraphs = List.rev filtered)
    
      let evalutator = lazy (Some <| (FsiEvaluator() :> IFsiEvaluator))
      let readPost filePath =
        // parse the post markup file
        let doc = Literate.ParseMarkdownFile (filePath, ?fsiEvaluator = evalutator.Value)
        
        // generate html code from the markdown
        let ctx = formattingContext None (Some OutputKind.Html) (Some true) None None
        let doc =
          doc
          |> editLiterateDocument ctx
          |> Transformations.replaceLiterateParagraphs ctx
        let heading, doc = extractHeading doc
        let content = Formatting.format doc.MarkdownDocument ctx.GenerateHeaderAnchors ctx.OutputKind
        let rec getTeaser (currentTeaser:string) (paragraphs:MarkdownParagraphs) =
          if currentTeaser.Length > 150 then currentTeaser
          else
            match paragraphs with
            | p :: t ->
              let convert = Formatting.format (doc.With(paragraphs = [p]).MarkdownDocument) ctx.GenerateHeaderAnchors ctx.OutputKind
              getTeaser (currentTeaser + convert) t
            | _ -> currentTeaser
    
        let title, date, tags, author =
          match heading with
          | Some header ->
            let headerValues =
              header.TrimEnd().Split([|"; "|], StringSplitOptions.RemoveEmptyEntries)
              |> Seq.map parseHeaderLine
              |> dict
            
            Title headerValues.["Title"], parseRawDate headerValues.["Date"],
            (match headerValues.TryGetValue "Tags" with
            | true, tags -> tags.Split([|","|], StringSplitOptions.RemoveEmptyEntries)
            | _ -> [||]),
            match headerValues.TryGetValue "Author" with
            | true, author -> author
            | _ -> "Unknown"
          | None ->
            let name = Path.GetFileNameWithoutExtension filePath
            let title, date = parseRawTitle name
            title, date, [||], "Unknown"
    
        let tipsHtml = doc.FormattedTips
        { Date = date; Title = title; Content = RawHtml content; TipsHtml = RawHtml tipsHtml; 
          Tags = tags |> List.ofArray; Author = author; Teaser = RawHtml (getTeaser "" doc.Paragraphs) }
    
      let toStrippedTitle (Title title) =
        StrippedTitle (title.Substring(0, Math.Min(title.Length, 50)))
    
      let readDatabase path : PostDb =
        // Blogposts are *.md files within the given path
        Directory.EnumerateFiles(path, "*.md")
        |> Seq.map (readPost >> (fun p -> (p.Date, toStrippedTitle p.Title), p))
        |> dict
