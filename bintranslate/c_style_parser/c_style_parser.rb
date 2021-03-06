require 'treetop'

# Load our custom syntax node classes so the parser can use them
require File.expand_path(File.join(File.dirname(__FILE__), 'ast_nodes.rb'))

class Parser
  
  # Load the Treetop grammar from the 'binfix_dsl' file, and create a new
  # instance of that parser as a class variable so we don't have to re-create
  # it every time we need to parse a string
  Treetop.load(File.expand_path(File.join(File.dirname(__FILE__), 'binfix_dsl.treetop')))
  @@parser = BinFix_DSLParser.new
  
  # Parse an input string and return a Ruby array like:
  #   [:this, :is, [:a, :test]]
  def self.parse(data)
    
    # Pass the data over to the parser instance
    tree = @@parser.parse(data)
    
    # If the AST is nil then there was an error during parsing
    # we need to report a simple error message to help the user
    if(tree.nil?)
      return nil, @@parser.failure_reason
    end
    
    # Remove all syntax nodes that aren't one of our custom
    # classes. If we don't do this we will end up with a *lot*
    # of essentially useless nodes
    #self.clean_tree(tree)
    
    # Convert the AST into an array representation of the input
    # structure and return it
    return tree
  end
  
  private
  
    def self.clean_tree(root_node)
      return if(root_node.elements.nil?)
      root_node.elements.delete_if{|node| node.class.name == "Treetop::Runtime::SyntaxNode" }
      root_node.elements.each {|node| self.clean_tree(node) }
    end

end

#expression = "4 + 5"
#ast = Parser.parse(expression);
#p ast