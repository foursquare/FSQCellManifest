Pod::Spec.new do |s|
  s.name      = 'FSQCellManifest'
  s.version   = '1.3.2'
  s.platform  = :ios, '8.0'
  s.summary   = 'A UITableView and UICollectionView delegate and datasource that provides a simpler unified interface for describing your sections and cells.'
  s.homepage  = 'https://github.com/foursquare/FSQCellManifest'
  s.license   = { :type => 'Apache', :file => 'LICENSE.txt' }
  s.authors   = { 'Brian Dorfman' => 'https://twitter.com/bdorfman' }
  s.source    = { :git => 'https://github.com/foursquare/FSQCellManifest.git',
                  :tag => "v#{s.version}" }
  s.source_files  = 'FSQCellManifest/*.{h,m}'
  s.requires_arc  = true
  s.dependency 'FSQMessageForwarder', '~> 1.0'
end
