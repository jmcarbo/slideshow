$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'optparse'
require 'erb'
require 'redcloth'
require 'maruku'
require 'logger'
require 'fileutils'
require 'ftools'
require 'hpricot'
#require 'uv'

#$KCODE="U"
module Slideshow

  VERSION = '0.6.1'

class Params 
  
  def initialize( name, headers )
    @svgname =  "#{name}.svg"
    @cssname =  "#{name}.css"
    @headers =  headers
  end
    
  def params_binding
    binding
  end

end

# todo: split (command line) options and headers?
# e.g. share (command line) options between slide shows (but not headers?)

class Opts
  
  def initialize
    @hash = {}
  end
    
  def put( key, value )
    key = normalize_key( key )
    setter = "#{key}=".to_sym

    if respond_to? setter
      send setter, value
    else
      @hash[ key ] = value
    end
  end
  
  def code_theme=( value )
    @hash[ :code_theme ] = value.tr( '-', '_' )
  end

  def gradient=( value )
    put_gradient( value, :theme, :color1, :color2 )
  end
  
  def gradient_colors=( value )
    put_gradient( value, :color1, :color2 )
  end

  def gradient_color=( value )
    put_gradient( value, :color1 )
  end
  
  def gradient_theme=( value )
    put_gradient( value, :theme )
  end
  
  def []( key )
    value = @hash[ normalize_key( key ) ]
    if value.nil?
      puts "** Warning: header '#{key}' undefined"
      "- #{key} not found -"
    else
      value 
    end
  end

  def generate?
    get_boolean( 'generate', false )
  end
  
  def has_includes?
    @hash[ :include ]
  end
  
  def output_path
    @hash[ :output ] ||= 'slides'
  end
  
  def includes
    # fix: use os-agnostic delimiter (use : for Mac/Unix?)
    has_includes? ? @hash[ :include ].split( ';' ) : []
  end
  
  def s5?  
    get_boolean( 's5', false )
  end
  
  def fullerscreen?
    get_boolean( 'fuller', false ) || get_boolean( 'fullerscreen', false )
  end

  def code_theme
    get( 'code-theme', DEFAULTS[ :code_theme ] )
  end  
  
  def code_line_numbers?
    get_boolean( 'code-line-numbers', DEFAULTS[ :code_line_numbers ] )
  end 

  DEFAULTS =
  {
    :title             => 'Untitled Slide Show',
    :footer            => '',
    :subfooter         => '',
    :gradient_theme    => 'dark',
    :gradient_color1   => 'red',
    :gradient_color2   => 'black',
    :code_theme        => 'amy',
    :code_line_numbers => 'true'
  }

  def set_defaults      
    DEFAULTS.each_pair do | key, value |
      @hash[ key ] = value if @hash[ key ].nil?
    end
  end

private

  def normalize_key( key )
    key.to_s.downcase.tr('-', '_').to_sym
  end
  
  # Assigns the given gradient-* keys to the values in the given string.
  def put_gradient( string, *keys )
    values = string.split( ' ' )

    values.zip(keys).each do |v, k|
      @hash[ normalize_key( "gradient-#{k}" ) ] = v.tr( '-', '_' )
    end
  end
  
  def get( key, default )
    @hash.fetch( normalize_key(key), default )
  end

  def get_boolean( key, default )
    value = @hash[ normalize_key( key ) ]
    if value.nil?
      default
    else
      (value == true || value =~ /true|yes|on/i) ? true : false
    end
  end

end # class Opts


class Gen

  KNOWN_TEXTILE_EXTNAMES  = [ '.textile', '.t' ]
  KNOWN_MARKDOWN_EXTNAMES = [ '.markdown', '.mark', '.m', '.txt', '.text' ]

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @opts = Opts.new
  end

  def logger 
    @logger
  end
  
  def opts
    @opts
  end

  def cache_dir
    PLATFORM =~ /win32/ ? win32_cache_dir : File.join(File.expand_path("~"), ".slideshow")
  end

  def win32_cache_dir
    unless File.exists?(home = ENV['HOMEDRIVE'] + ENV['HOMEPATH'])
      puts "No HOMEDRIVE or HOMEPATH environment variable.  Set one to save a" +
           "local cache of stylesheets for syntax highlighting and more."
      return false
    else
      return File.join(home, 'slideshow')
    end
  end

  def load_template( name, builtin )
    
    if opts.has_includes? 
      opts.includes.each do |path|
        logger.debug "File.exists? #{path}/#{name}"
        
        if File.exists?( "#{path}/#{name}" ) then          
          puts "Loading custom template #{path}/#{name}..."
          return File.read( "#{path}/#{name}" )
        end
      end       
    end
    
    # fallback load builtin template packaged with gem
    load_builtin_template( builtin )
  end

  def load_builtin_template( name )
    templatesdir = "#{File.dirname(__FILE__)}/templates"
    logger.debug "templatesdir=#{templatesdir}"

    File.read( "#{templatesdir}/#{name}" )
  end

  def render_template( content, b=TOPLEVEL_BINDING )
    ERB.new( content ).result( b )
  end


  def create_slideshow_templates

    files =
    case
    when opts.s5?
      [[ 's5/header.html.erb', 'header.html.erb' ],
       [ 's5/footer.html.erb', 'footer.html.erb' ],
       [ 's5/style.css.erb',   'style.css.erb'   ]]
    when opts.fullerscreen?  # use fullerscreen templates
      [[ 'header.html.erb', 'header.html.erb' ], 
       [ 'footer.html.erb', 'footer.html.erb' ], 
       [ 'style.css.erb',   'style.css.erb' ]]       
    else  # use default s6 templates
      [[ 's6/header.html.erb', 'header.html.erb'  ],
       [ 's6/footer.html.erb', 'footer.html.erb'  ],
       [ 's6/style.css.erb',   'style.css.erb'    ]]
    end
  
    # background theming shared between s5/s6/fullerscreen
    files << [ 'gradient.svg.erb',   'gradient.svg.erb' ]
         
    files.each do |file|
      source = "#{File.dirname(__FILE__)}/templates/#{file[0]}"
      dest   = "#{file[1]}"
        
      puts  "Copying '#{source}' to '#{dest}'"     
      File.copy( source, dest )
    end
    
    puts "Done."
  end

  def create_slideshow( fn )

  if opts.s5?
    headerdoc   = load_template( 'header.html.erb', 's5/header.html.erb' )
    footerdoc   = load_template( 'footer.html.erb', 's5/footer.html.erb' )
    styledoc    = load_template( 'style.css.erb',   's5/style.css.erb' )
  elsif opts.fullerscreen?  # use fullerscreen templates
    headerdoc   = load_template( 'header.html.erb', 'header.html.erb' )
    footerdoc   = load_template( 'footer.html.erb', 'footer.html.erb' )
    styledoc    = load_template( 'style.css.erb',   'style.css.erb' )      
  else  # use default s6 templates
    headerdoc   = load_template( 'header.html.erb', 's6/header.html.erb' )
    footerdoc   = load_template( 'footer.html.erb', 's6/footer.html.erb' )
    styledoc    = load_template( 'style.css.erb',   's6/style.css.erb' )    
  end
  
  # background theming shared between s5/s6/fullerscreen
  gradientdoc = load_template( 'gradient.svg.erb', 'gradient.svg.erb' )
  fpath = File.dirname(fn)
  basename = File.basename( fn, '.*' )
  extname  = File.extname( fn )
  outpath = File.expand_path(opts.output_path) # expands in current dir!!
  Dir.mkdir(outpath) unless File.directory? outpath

  known_extnames = KNOWN_TEXTILE_EXTNAMES + KNOWN_MARKDOWN_EXTNAMES
                
  if extname.empty? then
    extname  = ".textile"   # default to .textile 
    
    known_extnames.each do |e|
       logger.debug "File.exists? #{basename}#{e}"
       if File.exists?( "#{basename}#{e}" ) then         
          extname = e
          logger.debug "extname=#{extname}"
          break
       end
    end     
  end

  inname  =  "#{fpath}/#{basename}#{extname}"
  outname =  "#{outpath}/#{basename}.html"
  svgname =  "#{outpath}/#{basename}.svg"
  cssname =  "#{outpath}/#{basename}.css"

  logger.debug "inname=#{inname}"
  
  content = File.read( inname )
  
  # read source document
  # strip leading optional headers (key/value pairs) including optional empty lines

  read_headers = true
  content = ""

  File.open( inname ).readlines.each do |line|
    if read_headers && line =~ /^\s*(\w[\w-]*)[ \t]*:[ \t]*(.*)/
      key = $1.downcase
      value = $2.strip
    
      logger.debug "  adding option: key=>#{key}< value=>#{value}<"
      opts.put( key, value )
    elsif line =~ /^\s*$/
      content << line  unless read_headers
    else
      read_headers = false
      content << line
    end
  end

  # run pre-filters (built-in macros)
  # o replace {{{  w/ <pre class='code'>
  # o replace }}}  w/ </pre>
  content.gsub!( "{{{{{{", "<pre class='code'>_S9BEGIN_" )
  content.gsub!( "}}}}}}", "_S9END_</pre>" )  
  content.gsub!( "{{{", "<pre class='code'>" )
  content.gsub!( "}}}", "</pre>" )
  # restore escaped {{{}}} I'm sure there's a better way! Rubyize this! Anyone?
  content.gsub!( "_S9BEGIN_", "{{{" )
  content.gsub!( "_S9END_", "}}}" )

  opts.set_defaults
  
  params = Params.new( basename, opts )

  puts "Preparing slideshow theme '#{svgname}'..."
  
  out = File.new( svgname, "w+" )
  out << render_template( gradientdoc, params.params_binding )
  out.flush
  out.close 
  
  puts "Preparing slideshow '#{outname}'..."

  # convert light-weight markup to hypertext
  
  if KNOWN_MARKDOWN_EXTNAMES.include?( extname )
    content = Maruku.new( content, {:on_error => :raise} ).to_html
    # old code: content = BlueCloth.new( content ).to_html
  else
    # turn off hard line breaks
    # turn off span caps (see http://rubybook.ca/2008/08/16/redcloth)
    red = RedCloth.new( content, [:no_span_caps] )
    red.hard_breaks = false
    content = red.to_html
  end
  

  # post-processing

  slide_counter = 0
  content2 = ''
  
  # wrap h1's in slide divs; note use just <h1 since some processors add ids e.g. <h1 id='x'>
  content.each_line do |line|
     if line.include?( '<h1' ) then
        content2 << "\n\n</div>"  if slide_counter > 0
        content2 << "<div class='slide'>\n\n"
        slide_counter += 1
     end
     content2 << line
  end
  content2 << "\n\n</div>"   if slide_counter > 0

  ## todo: run syntax highlighting before markup/textilize? lets us add textile to highlighted code?
  ##  avoid undoing escaped entities?
  
  include_code_stylesheet = false
  # syntax highlight code
  # todo: can the code handle escaped entities? e.g. &gt; 
  doc = Hpricot(content2)
    doc.search("pre.code, pre > code").each do |e|
      if e.inner_html =~ /^\s*#!(\w+)/
        lang = $1.downcase
        if e.inner_html =~ /^\{\{\{/  # {{{ assumes escape/literal #!lang 
          # do nothing; next
          logger.debug "  skipping syntax highlighting using lang=#{lang}; assumimg escaped literal"
        else         
          logger.debug "  syntax highlighting using lang=#{lang}"
          if Uv.syntaxes.include?(lang)
            code = e.inner_html.sub(/^\s*#!\w+/, '').strip
            
            code.gsub!( "&lt;", "<" )
            code.gsub!( "&gt;", ">" )
            code.gsub!( "&amp;", "&" )
            # todo: missing any other entities? use CGI::unescapeHTML?
            logger.debug "code=>#{code}<"
            
            code_highlighted = Uv.parse( code, "xhtml", lang, opts.code_line_numbers?, opts.code_theme )
            # old code: e.inner_html = code_highlighted
            # todo: is it ok to replace the pre.code enclosing element to avoid duplicates?
            e.swap( code_highlighted )
            include_code_stylesheet = true
          end
        end
      end
    end

   content2 = doc.to_s


  out = File.new( outname, "w+" )
  out << render_template( headerdoc, params.params_binding )
  out << content2 
  out << render_template( footerdoc, params.params_binding )
  out.flush
  out.close

  puts "Preparing slideshow stylesheet '#{cssname}'..."

  out = File.new( cssname, "w+" )
  out << render_template( styledoc, params.params_binding )
  
  if include_code_stylesheet
     logger.debug "cache_dir=#{cache_dir}"

     FileUtils.mkdir(cache_dir) unless File.exists?(cache_dir) if cache_dir
     Uv.copy_files "xhtml", cache_dir

     theme = opts.code_theme
  
     theme_content = File.read( "#{cache_dir}/css/#{theme}.css" )
     
     out << "/* styles for code syntax highlighting theme '#{theme}' */\n"
     out << "\n"
     out << theme_content
  end
  
  out.flush
  out.close

  
  if opts.s5?
    # copy s5 machinery to s5 folder
    # todo/fix: is there a better way to check if the dir exists?
    Dir.mkdir( outpath + '/s5' ) unless File.directory?( outpath + '/s5' )
  
    [ 'opera.css', 'outline.css', 'print.css', 's5-core.css', 'slides.js' ].each do |name|

      source = "#{File.dirname(__FILE__)}/templates/s5/#{name}"
      dest   = "#{outpath}/s5/#{name}"
        
      logger.debug "copying '#{source} ' to '#{dest}'"     
      File.copy( source, dest )
    end
  elsif opts.fullerscreen?
     # do nothing; slideshow machinery built into plugin (requires install!)
  else
    # copy s6 machinery to s6 folder
    Dir.mkdir( outpath + '/s6' ) unless File.directory?(outpath +  '/s6' )
  
    [ 'outline.css', 'print.css', 'slides.css', 'slides.js', 'jquery.js' ].each do |name|

      source = "#{File.dirname(__FILE__)}/templates/s6/#{name}"
      dest   = "#{outpath}/s6/#{name}"
        
      logger.debug "copying '#{source} ' to '#{dest}'"     
      File.copy( source, dest )
    end    
  end

  puts "Done."
end


def run( args )

  opt=OptionParser.new do |cmd|
    
    cmd.banner = "Usage: slideshow [options] name"
    
    #todo/fix: use -s5 option without optional hack? possible with OptionParser package/lib?
    # use -5 switch instead?
    cmd.on( '-s[OPTIONAL]', '--s5', 'S5 Compatible Slide Show' ) { opts.put( 's5', true ) }
    cmd.on( '-f[OPTIONAL]', '--fullerscreen', 'FullerScreen Compatible Slide Show' ) { opts.put( 'fuller', true ) }
    # opts.on( "-s", "--style STYLE", "Select Stylesheet" ) { |s| $options[:style]=s }
    # opts.on( "-v", "--version", "Show version" )  {}
    
    cmd.on( '-g', '--generate',  'Generate Slide Show Templates' ) { opts.put( 'generate', true ) }
    # use -d or -o  to select output directory for slideshow or slideshow templates?
    # cmd.on( '-d', '--directory DIRECTORY', 'Output Directory' ) { |s| opts.put( 'directory', s )  }
    cmd.on( '-i', '--include PATH', 'Load Path' ) { |s| opts.put( 'include', s ) }
    cmd.on( '-o', '--output PATH', 'outputs to Path' ) { |s| opts.put( 'output', s ) }
    
    cmd.on( "-t", "--trace", "Show debug trace" ) {
       logger.datetime_format = "%H:%H:%S"
       logger.level = Logger::DEBUG
     }
    cmd.on_tail( "-h", "--help", "Show this message" ) {
         puts 
         puts "Slide Show (S9) is a free web alternative to PowerPoint or KeyNote in Ruby"
         puts
         puts cmd.help
         puts
         puts "Examples:"
         puts "  slideshow microformats"
         puts "  slideshow microformats.textile"
         puts "  slideshow -s5 microformats  # S5 compatible"
         puts "  slideshow -f microformats   # FullerScreen compatible"
         puts 
         puts "More examles:"
         puts "  slideshow -g      # Generate slide show templates"
         puts "  slideshow -g -s5  # Generate S5 compatible slide show templates"
         puts "  slideshow -g -f   # Generate FullerScreen compatible slide show templates"
         puts
         puts "  slideshow -i . microformats     # Use slide show templates in path ."
         puts "  slideshow -i . -s5 microformats # Use S5 compatible slide show templates in path ."
         puts
         puts "Further information:"
         puts "  http://slideshow.rubyforge.org" 
         exit
       }
  end

  opt.parse!( args )

  puts "Slide Show (S9) Version: #{VERSION} on Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"

  if opts.generate?
    create_slideshow_templates
  else
    args.each { |fn| create_slideshow( fn ) }
  end
end

end # class Gen

def Slideshow.main
  Gen.new.run(ARGV)
end

end # module Slideshow

Slideshow.main if __FILE__ == $0