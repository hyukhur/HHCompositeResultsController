Pod::Spec.new do |s|
  s.name         = "HHCompositeResultsController"
  s.version      = "0.0.1"
  s.summary      = "NSFetchedResultsController Composite Object using multiple NSFetchedResultsController."

  s.description  = <<-DESC
  		 NSFetchedResultsController Composite Object using multiple NSFetchedResultsController.
                   DESC

  s.homepage     = "https://github.com/hyukhur/HHCompositeResultsController"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Hyuk Hur" => "hyukhur@gmail.com" }
  s.social_media_url   = "http://twitter.com/hyukhur"
  s.platform     = :ios, "5.0"
  s.source       = { :git => "https://github.com/hyukhur/HHCompositeResultsController.git", :tag => s.version.to_s }
  s.source_files  = "HHCompositeResultsController/Classes", "Classes/**/*.{h,m}"
  s.public_header_files = "HHCompositeResultsController/Classes/**/*.h"
  s.requires_arc = true
end
