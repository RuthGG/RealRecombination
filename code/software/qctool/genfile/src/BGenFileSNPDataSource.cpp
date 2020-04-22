
//          Copyright Gavin Band 2008 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

#include <iostream>
#include <string>
#include <boost/bind.hpp>
#include <boost/format.hpp>
#include "genfile/snp_data_utils.hpp"
#include "genfile/SNPDataSource.hpp"
#include "genfile/bgen/bgen.hpp"
#include "genfile/BGenFileSNPDataSource.hpp"
#include "genfile/zlib.hpp"

namespace genfile {
	BGenFileSNPDataSource::BGenFileSNPDataSource( std::auto_ptr< std::istream > stream, Chromosome missing_chromosome ):
		m_filename( "(anonymous stream)" ),
		m_missing_chromosome( missing_chromosome )
	{
		setup( stream ) ;
	}
	
	BGenFileSNPDataSource::BGenFileSNPDataSource( std::string const& filename, Chromosome missing_chromosome ):
		m_filename( filename ),
		m_missing_chromosome( missing_chromosome )
	{
		setup(
			open_binary_file_for_input(
				filename,
				get_compression_type_indicated_by_filename( filename )
			)
		) ;
	}

	void BGenFileSNPDataSource::reset_to_start_impl() {
		stream().clear() ;
		stream().seekg(0) ;

		// read offset again and skip to first SNP data block
		bgen::uint32_t offset ;
		bgen::read_offset( (*m_stream_ptr), &offset ) ;
		m_stream_ptr->ignore( offset ) ;
	}

	SNPDataSource::Metadata BGenFileSNPDataSource::get_metadata() const {
		std::map< std::string, std::string > format ;
		format[ "ID" ] = "GP" ;
		format[ "Number" ] = "G" ;
		format[ "Type" ] = "Float" ;
		format[ "Description" ] = "Genotype call probabilities" ;
		SNPDataSource::Metadata result ;
		result.insert( std::make_pair( "FORMAT", format )) ;
		return result ;
	}

	void BGenFileSNPDataSource::get_sample_ids( GetSampleIds getter ) const {
		if( m_sample_ids ) {
			for( std::size_t i = 0; i < m_sample_ids->size(); ++i ) {
				getter( i, m_sample_ids->at(i) ) ;
			}
		}
	}
	
	std::string BGenFileSNPDataSource::get_source_spec() const {
		std::string result = m_filename + " (";
		if( (m_bgen_context.flags & bgen::e_Layout) == bgen::e_Layout0 ) {
			result += "bgen v1.0; " ;
		} else if( (m_bgen_context.flags & bgen::e_Layout) == bgen::e_Layout1 ) {
			result += "bgen v1.1; " ;
		} else if( (m_bgen_context.flags & bgen::e_Layout) == bgen::e_Layout2 ) {
			result += "bgen v1.2; " ;
		} else {
			assert(0);
		}
		
		result += (
			genfile::string_utils::to_string( m_bgen_context.number_of_samples )
			+ ( m_sample_ids ? " named samples; " : " unnamed samples; ")
		) ;
		
		if( (m_bgen_context.flags & bgen::e_CompressedSNPBlocks) == bgen::e_ZlibCompression ) {
			result += "zlib compression" ;
		} else if( (m_bgen_context.flags & bgen::e_CompressedSNPBlocks) == bgen::e_ZstdCompression ) {
			result += "zstd compression" ;
		} else {
			result += "uncompressed" ;
		}
		return result + ")" ;
	}

	namespace {
		void set_number_of_alleles( std::vector< std::string >* result, std::size_t n ) {
			result->resize(n) ;
		}
		void set_allele( std::vector< std::string >* result, std::size_t i, std::string value ) {
			(*result)[i] = value ;
		}
	}

	void BGenFileSNPDataSource::read_snp_identifying_data_impl( VariantIdentifyingData* result ) {
		std::string SNPID, rsid ;
		uint32_t position ;
		std::string chromosome_string ;
		std::vector< std::string > alleles ;
		if(
			bgen::read_snp_identifying_data( stream(), m_bgen_context, &SNPID, &rsid, &chromosome_string, &position,
			boost::bind( &set_number_of_alleles, &alleles, _1 ),
			boost::bind( &set_allele, &alleles, _1, _2 )
		) ) {
			Chromosome chromosome ;
			if( chromosome_string == "" ) {
				chromosome = m_missing_chromosome ;
			} else {
				chromosome = chromosome_string ;
			}
			*result = VariantIdentifyingData( rsid ) ;
			if( SNPID.size() > 0 ) {
				result->add_identifier( SNPID ) ;
			}
			result->set_position( GenomePosition( chromosome, position ) ) ;
			for( std::size_t i = 0; i < alleles.size(); ++i ) {
				result->add_allele( alleles[i] ) ;
			}
		}
	}

	namespace impl {
		struct BGenFileSNPDataReader: public VariantDataReader {
			BGenFileSNPDataReader( BGenFileSNPDataSource& source ):
				m_source( source )
			{
				assert( source ) ;
				bgen::read_genotype_data_block(
					m_source.stream(),
					m_source.bgen_context(),
					&m_source.m_compressed_data_buffer
				) ;
			}
			
			BGenFileSNPDataReader& get( std::string const& spec, PerSampleSetter& setter ) {
				assert( spec == "GP" || spec == ":genotypes:" ) ;
				bgen::uncompress_probability_data(
					m_source.bgen_context(),
					m_source.m_compressed_data_buffer,
					&(m_source.m_uncompressed_data_buffer)
				) ;
				bgen::parse_probability_data(
					&(m_source.m_uncompressed_data_buffer)[0],
					&(m_source.m_uncompressed_data_buffer)[0] + m_source.m_uncompressed_data_buffer.size(),
					m_source.bgen_context(),
					setter
				) ;
				return *this ;
			}
			
			bool supports( std::string const& spec ) const {
				return spec == "GP" || spec == ":genotypes:";
			}
			
			std::size_t get_number_of_samples() const {
				return m_source.number_of_samples() ;
			}

			void get_supported_specs( SpecSetter setter ) const {
				setter( "GP", "Float" ) ;
				//setter( ":genotypes:", "Float" ) ;
			}

		private:
			BGenFileSNPDataSource& m_source ;
			std::vector< double > m_genotypes ;
		} ;
	}

	VariantDataReader::UniquePtr BGenFileSNPDataSource::read_variant_data_impl() {
		return VariantDataReader::UniquePtr( new impl::BGenFileSNPDataReader( *this )) ;
	}

	void BGenFileSNPDataSource::ignore_snp_probability_data_impl() {
		bgen::ignore_genotype_data_block(
			stream(),
			m_bgen_context
		) ;
	}

	void BGenFileSNPDataSource::setup( std::auto_ptr< std::istream > stream ) {
		m_stream_ptr = stream ;
		bgen::uint32_t offset = 0 ;
		bgen::read_offset( *m_stream_ptr, &offset ) ;
		std::size_t bytes_read = bgen::read_header_block( *m_stream_ptr, &m_bgen_context ) ;

		if( offset < m_bgen_context.header_size() ) {
			throw FileStructureInvalidError() ;
		}
		
		if( m_bgen_context.flags & bgen::e_SampleIdentifiers ) {
			m_sample_ids = std::vector< std::string >() ;
			m_sample_ids->reserve( m_bgen_context.number_of_samples ) ;
			void(std::vector<std::string>::*push_back)(std::string const&) = &std::vector<std::string>::push_back;	
			bytes_read += bgen::read_sample_identifier_block(
				*m_stream_ptr,
				m_bgen_context,
				boost::bind(
					push_back,
					&(*m_sample_ids),
					_1
				)
			) ;
			assert( m_sample_ids->size() == m_bgen_context.number_of_samples ) ;
		}
		if( offset < bytes_read ) {
			throw FileStructureInvalidError() ;
		}
		// skip any remaining bytes before the first snp block
		m_stream_ptr->ignore( offset - bytes_read ) ;
		if( !*m_stream_ptr ) {
			throw FileStructureInvalidError() ;
		}
	}
}	

