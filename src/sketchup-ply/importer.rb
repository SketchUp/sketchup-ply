# jim.foltz@gmail.com

require 'sketchup'

module CommunityExtensions
  module PLY

    class PLYFile
      attr_reader :header, :elements, :file_type, :vertices, :faces, :mesh
      def initialize(filename)
        @filename = filename
        @elements = []
        @header = []
        @file_type = nil
        @valid = nil
        @comments = []
        @lines = []
        @scale = 1.0
        #@tr = Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees)
      end

      def ascii?
        @file_type == 'ascii'
      end
      def valid?
        @valid == true
      end

      def msg(str)
        Sketchup.status_text = str
      end
      def parse
        now = Time.now
        msg "Reading File."
        IO.readlines(@filename).each do |line|
          @lines.push(line.strip)
        end
        msg "Get_header"
        get_header()
        msg "Parse_header"
        parse_header()
        if !valid?
          UI.messagebox("Invalid or Binary .stl file.")
          return nil
        end
        msg "Parse elements"
        parse_elements()
        msg "Parse verts"
        parse_vertices()
        msg "Parse faces"
        parse_faces()
        elapsed = Time.now - now
        if UI.messagebox("Found #{faces().length} polyogns.\nContinue?", MB_OKCANCEL) == IDCANCEL
          return false
        end
        msg "Creating mesh..."
        create_mesh()
      end

      def create_mesh
        len = faces.length
        mesh = Geom::PolygonMesh.new(vertices.length, faces.length)
        faces.each do |face|
          mesh.add_polygon(face)
        end
        @mesh = mesh
      end

      def parse_vertices
        vertex_elem = find_element('vertex')
        vert_indices = vertex_elem.lines
        x_i = y_i = z_i = nil
        vertex_elem.props.each_with_index do |prop, i|
          x_i = i if prop[1] == 'x'
          y_i = i if prop[1] == 'y'
          z_i = i if prop[1] == 'z'
        end
        verts = []
        vertex_elem.lines.each do |ind|
          elems = @lines[ind].split
          vert = [
            elems[x_i].to_f*@scale,
            elems[y_i].to_f*@scale,
            elems[z_i].to_f*@scale
          ]
          #vert.transform!(@tr)
          verts << vert
        end
        @vertices = verts
      end

      def parse_faces
        #puts "face properties:"
        face_elem = find_element('face')
        list_index = nil
        face_elem.props.each_with_index do |prop, i|
          if (prop[0] == 'list' and (prop[-1] == 'vertex_index' or prop[-1] == 'vertex_indices'))
            list_index = i
          end
        end
        face_ind = []
        face_elem.lines.each do |ind|
          line = @lines[ind].split
          list_index.times { line.shift }
          num_verts = line.shift.to_i
          tarr = []
          num_verts.times { tarr << line.shift.to_i }
          if @zero_based != true and tarr.include?(0)
            @zero_based = true
          end
          face_ind.push( tarr )
        end
        faces = []
        face_ind.each {|els|
          face = els.map{|i|
            if !@zero_based
              i -= 1
            end
            @vertices[i]
          }
          faces.push(face)
        }
        @faces = faces
      end

      def find_element(name)
        tmp = nil
        @elements.each do |elem|
          if elem.name == name
            tmp = elem
            break
          end
        end
        return(tmp)
      end

      def parse_elements
        start = @header.length
        @elements.each_with_index do |element, i|
          element.qty.times do 
            element.add_line_index(start)
            start += 1
          end
        end
      end

      def get_header
        @lines.each_with_index do |line, i|
          line.strip!
          @header.push(line)
          if line[/end_header/]
            break
          end
        end
      end

      def parse_header
        #line = @lines.shift.strip
        if @header[0][/ply/]
          @valid = true
        end
        @header.each do |line|
          if line[/comment/]
            @comments.push(line)
          end
          if line[/format\s+(ascii|binary)/]
            @file_type = $1
            @valid = false if @file_type != 'ascii'
          end
          if line[/^element/]
            tmp, t, q = line.split
            elem = Element.new(t, q.to_i)
            @elements.push(elem)
          end
          if line[/^property/]
            prop, *rest = line.split
            @elements[-1].add_prop(rest)
          end
        end
        #return( elems )
      end

    end # class PLYFile

    class Element
      attr_reader :name, :qty, :props, :lines
      def initialize(name, qty)
        @name = name
        @qty = qty
        @start_index = 0
        @props = []
        @lines = []
      end
      def add_prop(prop)
        @props << prop
      end
      def add_line_index(index)
        @lines << index 
      end
    end

    def self.ply_import
      @tr = Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees)
      @scale = 1.0
      filename  = UI.openpanel "Select .ply file", nil, "*.ply"
      return unless filename
      ply_file = PLYFile.new(filename)
      st = ply_file.parse
      #p ply_file.valid?
      return unless st
      return unless ply_file.valid?
      #p ply_file

      entities = Sketchup.active_model.entities
      if entities.length > 0
        grp = entities.add_group
        entities = grp.entities
      end
      Sketchup.status_text = "Adding Mesh."
      Sketchup.active_model.start_operation("Import PLY file", true)
      entities.fill_from_mesh(ply_file.mesh, false, 0)
      Sketchup.active_model.commit_operation

    end

  end # module PLYFile
end # module CommunityExtensions

unless file_loaded?(__FILE__)
  menu = UI.menu("File")
  menu.add_item("Import .ply file") { CommunityExtensions::PLY.ply_import }
end
file_loaded(__FILE__)
