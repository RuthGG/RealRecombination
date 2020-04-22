
//          Copyright Gavin Band 2008 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

#include <vector>
#include <boost/foreach.hpp>
#include <boost/function.hpp>
#include <boost/tuple/tuple.hpp>
#include <boost/thread.hpp>
#include <boost/regex.hpp>
#include "genfile/VariantIdentifyingData.hpp"
#include "genfile/SNPDataSourceProcessor.hpp"
#include "genfile/SNPDataSourceChain.hpp"
#include "genfile/Error.hpp"
#include "components/SNPSummaryComponent/SNPSummaryComponent.hpp"
#include "components/SNPSummaryComponent/SNPSummaryComputation.hpp"
#include "components/SNPSummaryComponent/SNPSummaryComputationManager.hpp"
#include "qcdb/Storage.hpp"
#include "qcdb/FlatFileOutputter.hpp"
#include "qcdb/FlatTableDBOutputter.hpp"
#include "components/SNPSummaryComponent/AssociationTest.hpp"
#include "components/SNPSummaryComponent/SequenceAnnotation.hpp"
#include "components/SNPSummaryComponent/DifferentialMissingnessComputation.hpp"
#include "components/SNPSummaryComponent/StratifyingSNPSummaryComputation.hpp"
#include "components/SNPSummaryComponent/CrossDataSetConcordanceComputation.hpp"
#include "components/SNPSummaryComponent/CrossDataSetHaplotypeComparisonComputation.hpp"
#include "components/SNPSummaryComponent/GeneticMapAnnotation.hpp"
#include "components/SNPSummaryComponent/Bed3Annotation.hpp"
#include "components/SNPSummaryComponent/Bed4Annotation.hpp"
#include "components/SNPSummaryComponent/CallComparerComponent.hpp"
#include "components/SNPSummaryComponent/ClusterFitComputation.hpp"

void SNPSummaryComponent::declare_options( appcontext::OptionProcessor& options ) {
	options.declare_group( "SNP computation options" ) ;
	options[ "-snp-stats" ]
		.set_description( "Calculate and output per-SNP statistics." ) ;
	options[ "-snp-stats-columns" ]
        .set_description( "Comma-seperated list of extra columns to output in the snp-wise statistics file." )
		.set_takes_single_value()
		.set_default_value( "allele-frequencies,HWE,missingness,info" ) ;

	options.declare_group( "Intensity computation options" ) ;
	options[ "-intensity-stats" ]
		.set_description( "Compute intensity means and (co)variances for each genotype class at each SNP." ) ;
	options[ "-fit-clusters" ]
		.set_description( "Fit multivariate T distributions to each cluster." ) ;
	options[ "-fit-cluster-parameters" ]
		.set_description( "Specify parameters for cluster fit.  This should have three values, which are:"
			" 1. the degrees of freedom for the multivariate t.  Specify \"inf\" or ∞ to fit multivariate normal clusters."
			" 2. the variance of a diagonal variance matrix used for regularisation."
			" 3. the effective number of fake samples used for regularisation."
		)
		.set_takes_values( 3 )
		.set_default_value( 5 )
		.set_default_value( 0.0005 )
		.set_default_value( 1 )
	;
	options[ "-fit-cluster-scale" ]
		.set_description( "Specify scale to fit clusters in.  Either \"X:Y\" or \"contrast:logR\"." )
		.set_takes_values( 1 )
		.set_default_value( "X:Y" )
	;
	options.option_implies_option( "-fit-cluster-parameters", "-fit-clusters" ) ;
	options.option_implies_option( "-fit-cluster-scale", "-fit-clusters" ) ;
	
	options[ "-stratify" ]
		.set_description( "Compute all SNP summary statistics seperately for each level of the given variable in the sample file." )
		.set_takes_single_value() ;

	options[ "-differential" ]
		.set_description( "Test for differences in SNP summary statistics between the categories of the given variable."
			" Currently a test for differential missingness is performed." )
		.set_takes_single_value() ;
	
	options.declare_group( "Annotation options" ) ;
	options[ "-annotate-sequence" ]
		.set_description( "Specify a FASTA-formatted file containing reference alleles to annotate variants with."
			" This will appear as <name>_allele where <name> is the second argument." )
		.set_takes_values( 2 )
		.set_minimum_multiplicity( 0 )
		.set_maximum_multiplicity( 100 ) ;
	options[ "-flanking" ]
		.set_description( "Specify that flanking sequence annotations [ pos - a, pos + b ] should be output when using "
			"-annotate-sequence and -annotate-sequence" )
		.set_takes_values( 2 )
		.set_minimum_multiplicity( 0 )
		.set_maximum_multiplicity( 1 ) ;

	options[ "-annotate-genetic-map" ]
		.set_description( "Specify a genetic map file or files.  QCTOOL will interpolate the map "
			"to produce approximate positions in centiMorgans for each SNP in the data." )
		.set_takes_single_value() ;
	options[ "-annotate-bed3" ]
		.set_description( "Annotate variants with 1 or 0 according to whether the position of the variant "
			"is within an interval in one of the given BED files.  BED files must contain 0-based, right-open intervals "
			"which will be translated to 1-based coordinates for comparison with input data. " )
		.set_takes_values_until_next_option() ;
	options[ "-annotate-bed4" ]
		.set_description( "Annotate variants with the values (4th column) of a BED file according to the BED regions it lies in."
			" BED files must contain 0-based, right-open intervals which will be translated to 1-based coordinates for comparison"
			" with input data. " )
		.set_takes_values_until_next_option() ;
	options.declare_group( "Callset comparison options" ) ;
	options[ "-compare-to" ]
		.set_description( "Compute a matrix of values indicating concordance of samples between the main dataset and the dataset given as argument to this option. "
		 	"Values must be the genotype and sample files (in that order).  Samples are matched using the first ID column; "
			"SNPs are matched based on all the identifying information fields." )
		.set_takes_values( 2 )
		.set_minimum_multiplicity( 0 )
		.set_maximum_multiplicity( 1 ) ;
	options[ "-haplotypic" ]
		.set_description( "Instruct QCTOOL to perform haplotypic computations.  Currently this affects the -compare-to option only "
			"and turns on computation of switch error for two sets of haplotypes." ) ;
	options.option_implies_option( "-snp-stats", "-g" ) ;
	options.option_implies_option( "-intensity-stats", "-g" ) ;
	options.option_implies_option( "-fit-clusters", "-g" ) ;
	options.option_implies_option( "-annotate-sequence", "-g" ) ;
	options.option_implies_option( "-annotate-genetic-map", "-g" ) ;
	options.option_implies_option( "-stratify", "-s" ) ;
	options.option_implies_option( "-differential", "-s" ) ;
	options.option_implies_option( "-differential", "-osnp" ) ;
}

bool SNPSummaryComponent::is_needed( appcontext::OptionProcessor const& options ) {
	return options.check( "-snp-stats" )
		|| options.check( "-differential" )
		|| options.check( "-intensity-stats" )
		|| options.check( "-fit-clusters" )
		|| options.check( "-compare-to" )
		|| options.check( "-annotate-sequence" )
		|| options.check( "-annotate-genetic-map" )
		|| options.check( "-annotate-bed3" )
		|| options.check( "-annotate-bed4" )
	;
}

SNPSummaryComponent::UniquePtr SNPSummaryComponent::create(
	genfile::CohortIndividualSource const& samples,
	appcontext::OptionProcessor const& options,
	appcontext::UIContext& ui_context
) {
	return UniquePtr( new SNPSummaryComponent( samples, options, ui_context )) ;
}

SNPSummaryComponent::SNPSummaryComponent(
	genfile::CohortIndividualSource const& samples,
	appcontext::OptionProcessor const& options,
	appcontext::UIContext& ui_context
):
	m_samples( samples ),
	m_options( options ),
	m_ui_context( ui_context )
{}

void SNPSummaryComponent::setup(
	genfile::SNPDataSourceProcessor& processor,
	qcdb::Storage::SharedPtr storage
) {
	processor.add_callback( genfile::SNPDataSourceProcessor::Callback::UniquePtr(
		create_manager( storage ).release() )
	) ;
}

SNPSummaryComputationManager::UniquePtr SNPSummaryComponent::create_manager(
	qcdb::Storage::SharedPtr storage
) {
	SNPSummaryComputationManager::UniquePtr manager( new SNPSummaryComputationManager( m_samples, m_options.get_value< std::string >( "-sex-column" ) ) ) ;
	{
		std::string const coding_string = m_options.get< std::string >( "-haploid-genotype-coding" ) ;
		if( coding_string == "hom" ) {
			manager->set_haploid_genotype_coding( 2 ) ; 
		} else if( coding_string == "het" ) {
			manager->set_haploid_genotype_coding( 1 ) ; 
		} else {
			throw genfile::BadArgumentError( "SNPSummaryComponent::create_manager()", "-haploid-genotype-coding=\"" + coding_string + "\"", "Value should be \"hom\" or \"het\"." ) ;
		}
	}

	storage->add_variable( "comment" ) ;
	manager->add_result_callback(
		boost::bind(
			&qcdb::Storage::store_per_variant_data,
			storage,
			_1, _2, _3
		)
	) ;
	
	m_storage = storage ;
	
	add_computations( *manager, storage ) ;
	m_ui_context.logger() << "SNPSummaryComponent: the following components are in place:\n" << manager->get_summary( "  " ) << "\n" ;
	
	return manager ;
}

qcdb::Storage::SharedPtr SNPSummaryComponent::get_storage() const {
	return m_storage ;
}

namespace impl {
	
	typedef std::map< genfile::VariantEntry, std::vector< int > > StrataMembers ;

	StrataMembers compute_strata( genfile::CohortIndividualSource const& samples, std::string const& variable ) {
		StrataMembers result ;
		genfile::CohortIndividualSource::ColumnSpec const spec = samples.get_column_spec() ;
		if( !spec[ variable ].is_discrete() ) {
			throw genfile::BadArgumentError(
				"impl::compute_strata()",
				"variable=\"" + variable + "\"",
				"Expected \"" + variable + "\" to be a discrete variable (type B or D in the sample file)"
			) ;
		}

		for( std::size_t i = 0; i < samples.get_number_of_individuals(); ++i ) {
			genfile::VariantEntry const& entry = samples.get_entry( i, variable ) ;
			if( !entry.is_missing() ) {
				result[ samples.get_entry( i, variable ) ].push_back( int( i ) ) ;
			}
		}

		return result ;
	}
}

namespace {
	void parse_bed_annotation_spec( std::string const& spec, std::vector< genfile::string_utils::slice >* filenames, unsigned int* margin ) ;
}
	
void SNPSummaryComponent::add_computations( SNPSummaryComputationManager& manager, qcdb::Storage::SharedPtr storage ) const {
	using genfile::string_utils::split_and_strip_discarding_empty_entries ;
	using boost::regex_replace ;
	using boost::regex ;

	typedef std::map< std::string, qcdb::Storage::SharedPtr > Outputters ;
	Outputters outputters ;

	if( m_options.check( "-snp-stats" )) {
		std::vector< std::string > elts = split_and_strip_discarding_empty_entries( m_options.get_value< std::string >( "-snp-stats-columns" ), ",", " \t" ) ;
		BOOST_FOREACH( std::string const& elt, elts ) {
			manager.add_computation( elt, SNPSummaryComputation::create( elt )) ;
		}
	}
	
	if( m_options.check( "-snp-stats" )) {
		std::vector< std::string > elts = split_and_strip_discarding_empty_entries( m_options.get_value< std::string >( "-snp-stats-columns" ), ",", " \t" ) ;
		BOOST_FOREACH( std::string const& elt, elts ) {
			manager.add_computation( elt, SNPSummaryComputation::create( elt )) ;
		}
	}

	if( m_options.check( "-intensity-stats" )) {
		manager.add_computation( "intensity-stats", SNPSummaryComputation::create( "intensity-stats" )) ;
	}

	if( m_options.check( "-fit-clusters" )) {
		std::vector< std::string > params = m_options.get_values( "-fit-cluster-parameters" ) ;
		double nu = 0 ;
		if( genfile::string_utils::to_lower( params[0] ) == "inf" || params[0] == "∞" ) {
			nu = std::numeric_limits< double >::infinity() ;
		} else {
			nu = genfile::string_utils::to_repr< double >( params[0] ) ;
		}
		double regularisationVariance = genfile::string_utils::to_repr< double >( params[1] ) ;
		double regularisationCount = genfile::string_utils::to_repr< double >( params[2] ) ;
		snp_summary_component::ClusterFitComputation::UniquePtr computation(
			new snp_summary_component::ClusterFitComputation(
				nu, regularisationVariance, regularisationCount
			)
		) ;
		computation->set_scale( m_options.get< std::string >( "-fit-cluster-scale" )) ;
		manager.add_computation(
			"fit-clusters",
			SNPSummaryComputation::UniquePtr( computation.release() )
		) ;
	}

	if( m_options.check( "-compare-to" )) {
		std::vector< std::string > filenames = m_options.get_values< std::string >( "-compare-to" ) ;

		std::vector< std::string > sample_id_columns = genfile::string_utils::split(
			m_options.get< std::string >( "-match-sample-ids" ),
			"~"
		) ;
		
		if( sample_id_columns.size() != 2 ) {
			throw genfile::BadArgumentError(
				"SNPSummaryComponent::add_computations()",
				"-match-sample-ids " + m_options.get< std::string >( "-match-sample-ids" ),
				"Value should be of the form <id in main dataset>~<id in compared-to dataset>"
			) ;
		}
		snp_stats::CrossDataSetComparison::UniquePtr computation ;
		if( m_options.check( "-haplotypic" ) ) {
			computation.reset(
				new snp_stats::CrossDataSetHaplotypeComparisonComputation(
					m_samples,
					sample_id_columns[0]
				)
			) ;
		} else {
			computation.reset(
				new snp_stats::CrossDataSetConcordanceComputation(
					m_samples,
					sample_id_columns[0]
				)
			) ;
		}

		computation->set_comparer(
			genfile::VariantIdentifyingData::CompareFields(
				m_options.get_value< std::string >( "-compare-variants-by" ),
				m_options.check( "-match-alleles-to-cohort1" )
			)
		) ; 
	
		if( m_options.check( "-match-alleles-to-cohort1") ) {
			computation->set_match_alleles() ;
		}
	
		genfile::SNPDataSource::UniquePtr alternate_dataset(
			genfile::SNPDataSourceChain::create(
				genfile::wildcard::find_files_by_chromosome(
					filenames[0]
				),
				boost::optional< genfile::vcf::MetadataParser::Metadata >(),
				m_options.get< std::string >( "-filetype" )
			).release()
		) ;
		
		computation->set_alternate_dataset(
			genfile::CohortIndividualSource::create( filenames[1] ),
			sample_id_columns[1],
			alternate_dataset
		) ;

		manager.add_computation(
			"dataset_comparison",
			SNPSummaryComputation::UniquePtr(
				computation.release()
			)
		) ;
	}

	if( m_options.check( "-differential" )) {
		std::string const variable = m_options.get< std::string >( "-differential" ) ;
		impl::StrataMembers strata = impl::compute_strata( m_samples, variable ) ;
		manager.add_computation(
			"differential_missingness",
			DifferentialMissingnessComputation::create( variable, strata )
		) ;
	}

	if( m_options.check( "-stratify" )) {
		std::string const variable = m_options.get< std::string >( "-stratify" ) ;
		impl::StrataMembers strata = impl::compute_strata( m_samples, variable ) ;
		manager.stratify_by( strata, variable ) ;
	}
	
	if( m_options.check( "-annotate-sequence" )) {
		appcontext::UIContext::ProgressContext progress = m_ui_context.get_progress_context( "Loading reference sequence" ) ;
		std::vector< std::string > const elts = m_options.get_values< std::string >( "-annotate-sequence" ) ;
		if( elts.size() % 2 != 0 ) {
			throw genfile::BadArgumentError(
				"SNPSummaryComponent::add_computations()",
				"-annotate-sequence " + genfile::string_utils::join( elts, " " ),
				"-annotate-sequence takes an even number of arguments: <filename> <annotation name>..."
			) ;
		}
		for( std::size_t i = 0; i < elts.size(); i += 2 ) {
			SequenceAnnotation::UniquePtr computation(
				new SequenceAnnotation( elts[i+1], elts[i], progress )
			) ;
		
			if( m_options.check( "-flanking" )) {
				std::vector< std::size_t > data = m_options.get_values< std::size_t >( "-flanking" ) ;
				assert( data.size() == 2 ) ;
				computation->set_flanking( data[0], data[1] ) ;
			}
		
			manager.add_computation(
				elts[1] + "_sequence",
				SNPSummaryComputation::UniquePtr(
					computation.release()
				)
			) ;
		}
	}

	if( m_options.check( "-annotate-ancestral" )) {
		appcontext::UIContext::ProgressContext progress = m_ui_context.get_progress_context( "Loading ancestral sequence" ) ;
		SequenceAnnotation::UniquePtr computation(
			new SequenceAnnotation( "ancestral", m_options.get< std::string >( "-annotate-ancestral" ), progress )
		) ;
		
		if( m_options.check( "-flanking" )) {
			std::vector< std::size_t > data = m_options.get_values< std::size_t >( "-flanking" ) ;
			assert( data.size() == 2 ) ;
			computation->set_flanking( data[0], data[1] ) ;
		}

		manager.add_computation(
			"ancestral_sequence",
			SNPSummaryComputation::UniquePtr(
				computation.release()
			)
		) ;
	}

	if( m_options.check( "-annotate-genetic-map" )) {
		appcontext::UIContext::ProgressContext progress = m_ui_context.get_progress_context( "Loading genetic map" ) ;
		GeneticMapAnnotation::UniquePtr computation = GeneticMapAnnotation::create(
			genfile::wildcard::find_files_by_chromosome(
				m_options.get< std::string >( "-annotate-genetic-map" )
			),
			progress
		) ;
		
		manager.add_computation(
			"genetic_map",
			SNPSummaryComputation::UniquePtr(
				computation.release()
			)
		) ;
	}

	if( m_options.check( "-annotate-bed3" )) {
		Bed3Annotation::UniquePtr annotation = Bed3Annotation::create() ;

		{
			appcontext::UIContext::ProgressContext progress = m_ui_context.get_progress_context( "Loading bed intervals" ) ;
			std::vector< std::string > const& specs = m_options.get_values< std::string >( "-annotate-bed3" ) ;
			progress( 0, specs.size() ) ;
			for( std::size_t i = 0; i < specs.size(); ++i ) {
				std::vector< genfile::string_utils::slice > filenames ;
				unsigned int margin = 0 ;
				parse_bed_annotation_spec( specs[i], &filenames, &margin ) ;
				assert( filenames.size() > 0 ) ;
				for( std::size_t j = 0; j < filenames.size(); ++j ) {
					std::cerr << filenames[j] << ".\n" ;
					annotation->add_annotation(
						regex_replace( std::string( specs[i] ), regex( ".bed|.bed.gz" ), "" ),
						filenames[j],
						margin, margin
					) ;
				}
				progress( i+1, specs.size() ) ;
			}
		}
		
		manager.add_computation(
			"bed3_annotation",
			SNPSummaryComputation::UniquePtr(
				annotation.release()
			)
		) ;
	}

	if( m_options.check( "-annotate-bed4" )) {
		Bed4Annotation::UniquePtr annotation = Bed4Annotation::create() ;

		{
			appcontext::UIContext::ProgressContext progress = m_ui_context.get_progress_context( "Loading bed values" ) ;
			std::vector< std::string > const& specs = m_options.get_values< std::string >( "-annotate-bed4" ) ;
			progress( 0, specs.size() ) ;
			for( std::size_t i = 0; i < specs.size(); ++i ) {
				std::vector< genfile::string_utils::slice > filenames ;
				unsigned int margin = 0 ;
				parse_bed_annotation_spec( specs[i], &filenames, &margin ) ;
				assert( filenames.size() > 0 ) ;
				for( std::size_t j = 0; j < filenames.size(); ++j ) {
					std::cerr << filenames[j] << ".\n" ;
					annotation->add_annotation(
						regex_replace( std::string( specs[i] ), regex( ".bed|.bed.gz" ), "" ),
						filenames[j],
						margin, margin
					) ;
				}
				progress( i+1, specs.size() ) ;
			}
		}
		
		manager.add_computation(
			"bed4_annotation",
			SNPSummaryComputation::UniquePtr(
				annotation.release()
			)
		) ;
	}

#if 0
	if( m_options.check_if_option_was_supplied_in_group( "Call comparison options" ) ) {
		CallComparerComponent::UniquePtr cc = CallComparerComponent::create(
			m_samples,
			m_options,
			m_ui_context
		) ;

		cc->setup( manager, storage ) ;
	}
#endif
}

namespace {
	void parse_bed_annotation_spec(
		std::string const& spec,
		std::vector< genfile::string_utils::slice >* filenames,
		unsigned int* margin
	) {
		using genfile::string_utils::slice ;
		using genfile::string_utils::join ;
		using genfile::string_utils::to_repr ;
		assert( filenames ) ;
		filenames->clear() ;
		std::vector< slice > elts = slice( spec ).split( "+" ) ;
		assert( elts.size() > 0 ) ;
		if( elts.size() > 2 ) {
			throw genfile::BadArgumentError(
				"SNPSummaryComponent::parse_bed_annotation_spec()",
				"spec=\"" + spec + "\"",
				"Too many +'s in BED annotation spec."
			) ;
		}
		if( elts.size() == 2 ) {
			if( elts[1].size() < 3 || elts[1].substr( elts[1].size() - 2, elts[1].size() ) != "bp" ) {
				throw genfile::BadArgumentError(
					"SNPSummaryComponent::parse_bed_annotation_spec()",
					"spec=\"" + spec + "\"",
					"In \"" + spec + "\", margin should be of the form +<n>bp for a positive integer n."
				) ;
			}
			*margin = to_repr< unsigned int >( elts[1].substr( 0, elts[1].size() - 2 )) ; 
		}
		*filenames = elts[0].split( "," ) ;
	}
}

SNPSummaryComputation::UniquePtr SNPSummaryComponent::create_computation( std::string const& name ) const {
	if( name != "association_test" ) {
		return SNPSummaryComputation::UniquePtr( SNPSummaryComputation::create( name )) ;
	} else {
		assert(0) ;
	}
}
