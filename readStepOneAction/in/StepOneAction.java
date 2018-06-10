package fr.efl.production.efl3.meta.pipeline.action.impl;

import fr.efl.chaine.xslt.SaxonPipe;
import fr.efl.chaine.xslt.config.Xslt;
import fr.efl.production.efl3.meta.pipeline.action.PipelineAction;
import fr.efl.production.efl3.meta.pipeline.exception.PipelineException;
import fr.efl.production.efl3.meta.saxon.*;
import fr.efl.production.efl3.meta.source.SourceDao;
import fr.efl.production.efl3.meta.substitution.SubstitutionSet;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.TeeDestination;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.s9api.XsltCompiler;
import net.sf.saxon.s9api.XsltExecutable;
import net.sf.saxon.s9api.XsltTransformer;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.xml.transform.stream.StreamSource;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.util.Arrays;
import java.util.Map;
import java.util.Set;

import static fr.efl.production.efl3.meta.saxon.SaxonHelper.buildTransformer;
import static fr.efl.production.efl3.meta.saxon.SaxonHelper.closeQuietlySerializer;

/**
 * The step one action.
 */
public class StepOneAction extends AbstractFileAction {
	/** Logger. */
	private static final Logger LOGGER = LoggerFactory.getLogger(StepOneAction.class);
	/** The default stream buffer size. */
	private static final int BUF_SIZE = 10 * 1024;
	/** The output papidoc directory. */
	private static String outputPapidocDirectory;
	/** The saxon processor. */
	private static Processor processor;
	/** The filter if not indexed xslt. */
	private static XsltExecutable filterNotIndexedXslt;
	/** The lowercase xslt. */
	private static XsltExecutable lowercaseXslt;
	/** The inject cdcoll xslt. */
	private static XsltExecutable injectCdcollXslt;
	/** The inject conf dalloz xslt. */
	private static XsltExecutable injectConfigDallozXslt;
	/** The gen meta fiule xslt. */
	private static XsltExecutable genMetaFileXslt;
	/** The gen ur xslt. */
	private static XsltExecutable genUrXslt;
	/** The source repro xslt. */
	private static XsltExecutable genEstSourceReproXslt;
	/** The gen source xslt. */
	private static XsltExecutable genSourceXslt;
	/** The normalize xslt. */
	private static XsltExecutable normalizeXslt;
	/** The add meta xslt. */
	private static XsltExecutable addMetaXslt;
	/** The split by ur xslt. */
	private static XsltExecutable splitByUrXslt;
	/** The merge source xslt. */
	private static XsltExecutable mergeSourceBookXslt;
	/** The resolve txtlr article xslt. */
	private static XsltExecutable resolveTxtlrArticleXslt;
	/** The filter ur xslt. */
	private static XsltExecutable filterUrXslt;
	/** The filter jurica xslt. */
	private static XsltExecutable filterJuricaXslt;
	/** The filter not jurica xslt. */
	private static XsltExecutable filterNotJuricaXslt;
	/** The filter source xslt. */
	private static XsltExecutable filterSourceXslt;
	/** The gen search meta xslt. */
	private static XsltExecutable genSearchMetaXslt;
	/** The unduplicate titre_source by id_source_commentee meta xslt. */
	private static XsltExecutable unduplicateTitreSourceByIdSourceCommenteeXslt;
	/** The output papidoc xslt. */
	private static XsltExecutable outputPapidocXslt;
	/** The source dao. */
	private static SourceDao sourceDao;
	/** pdcs loaded. */
	private static Set<String> pdcs;
	/** The sources keys by pdc.*/
	private static Map<String, Set<String>> sourceKeysByPdc;
	/** The substitution set.*/
	private static SubstitutionSet substitutionSet;

	/**
	 * Initialize the action.
	 * @param templateDirectory the template directory
	 * @param xsltLoadFile the xslt load file
	 * @param outputPapidocDirectory the output papidoc directory
	 * @param sourceDao the source dao
	 * @param pdcs the pdcs
	 * @param sourceKeysByPdc the source keys by pdc
	 * @param substitutionSet the substitutionSet
	 * @throws SaxonApiException when a problem occurs
	 * @throws FileNotFoundException when a problem occurs
	 * @throws ClassNotFoundException when a problem occurs
	 * @throws NoSuchMethodException when a problem occurs
	 */
	public static void init(String templateDirectory, File[] xsltLoadFile,
							String outputPapidocDirectory,
							SourceDao sourceDao, Set<String> pdcs,
							Map<String, Set<String>> sourceKeysByPdc,
							SubstitutionSet substitutionSet)
			throws SaxonApiException, FileNotFoundException,
			ClassNotFoundException, NoSuchMethodException, MalformedURLException, URISyntaxException {
		StepOneAction.outputPapidocDirectory = outputPapidocDirectory;
		StepOneAction.processor = SaxonHelper.configureSaxon(Arrays.asList(xsltLoadFile));
		XsltCompiler xsltCompiler = processor.newXsltCompiler();
		lowercaseXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/lowercase.xsl"),
				xsltCompiler
		).getExecutable();
		injectCdcollXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/inject-cdcoll.xsl"),
				xsltCompiler
		).getExecutable();
		filterNotIndexedXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/filter-is-not-full-text-indexed.xsl"),
				xsltCompiler
		).getExecutable();
		injectConfigDallozXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/inject-config-dalloz.xsl"),
				xsltCompiler
		).getExecutable();
		genMetaFileXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/gen-meta-file.xsl"),
				xsltCompiler
		).getExecutable();
		genUrXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/gen-ur.xsl"),
				xsltCompiler
		).getExecutable();
		genEstSourceReproXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/gen-est-source-repro.xsl"),
				xsltCompiler
		).getExecutable();
		genSourceXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/gen-source.xsl"),
				xsltCompiler
		).getExecutable();
		normalizeXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/normalize.xsl"),
				xsltCompiler
		).getExecutable();
		addMetaXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/add-meta.xsl"),
				xsltCompiler
		).getExecutable();
		splitByUrXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/split-by-ur.xsl"),
				xsltCompiler
		).getExecutable();
		filterUrXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/filter-ur.xsl"),
				xsltCompiler
		).getExecutable();
		filterJuricaXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/filter-jurica.xsl"),
				xsltCompiler
		).getExecutable();
		filterNotJuricaXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/filter-not-jurica.xsl"),
				xsltCompiler
		).getExecutable();
		filterSourceXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/filter-source.xsl"),
				xsltCompiler
		).getExecutable();
		genSearchMetaXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/gen-search-meta.xsl"),
				xsltCompiler
		).getExecutable();
		unduplicateTitreSourceByIdSourceCommenteeXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/unduplicate-titresource-by-idsourcecommentee.xsl"),
				xsltCompiler
		).getExecutable();
		mergeSourceBookXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/merge-source-book.xsl"), xsltCompiler
		).getExecutable();
		resolveTxtlrArticleXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/resolve-txtlr-article.xsl"),
				xsltCompiler
		).getExecutable();
		outputPapidocXslt = SaxonPipe.loadTemplate(
				new Xslt(templateDirectory + "/output-papidoc.xsl"),
				xsltCompiler
		).getExecutable();
		StepOneAction.sourceDao = sourceDao;
		StepOneAction.pdcs = pdcs;
		StepOneAction.sourceKeysByPdc = sourceKeysByPdc;
		StepOneAction.substitutionSet = substitutionSet;
	}

	/**
	 * Works on in file.
	 * @throws PipelineException when a problem occurs
	 */
	@Override
	public void work() throws PipelineException {
		File inFile = getInFile();
		String originalThreadName = Thread.currentThread().getName();
		try {
			Thread.currentThread().setName(originalThreadName + "/" + inFile.getName());
			xsltWork(inFile);
		} finally {
			Thread.currentThread().setName(originalThreadName);
		}
	}

	/**
	 * Copy the current action.
	 * @return a new action
	 */
	@Override
	public PipelineAction<File, File> copy() {
		return new StepOneAction();
	}

	/**
	 * The xslt works on the specified file.
	 * @param input the specified file
	 * @return the input file
	 * @throws PipelineException when a problem occurs
	 */
	private File xsltWork(final File input) throws PipelineException {
		OutputStream outputPapidoc = null;
		OutputStream outputSrcPapidoc = null;
		SaveSourceInDatabaseDestination databaseDestination = null;
		Serializer papidocSerializer = null;
		Serializer papidocJuricaSerializer;
//		OutputStream debugOutput = null;
//		Serializer debugSerializer = null;

		try {

			String fileKey = input.getName().replace(".xml", "");
			databaseDestination = new SaveSourceInDatabaseDestination(sourceDao, sourceKeysByPdc, fileKey);
			outputPapidoc = new BufferedOutputStream(
					new FileOutputStream(outputPapidocDirectory + "/" + input.getName()),
					BUF_SIZE
			);
			papidocSerializer = processor.newSerializer(outputPapidoc);
			StreamBuilder outputSrcPapidocBuilder = new StreamBuilder() {
				@Override
				public OutputStream build() throws FileNotFoundException {
					String filename = outputPapidocDirectory + "/"
							+ input.getName().replace(".xml", "-src.xml");
					return new BufferedOutputStream(new FileOutputStream(filename), BUF_SIZE);
				}
			};
			outputSrcPapidoc = new WriteOnlyNotBlankOutputStream(outputSrcPapidocBuilder,
					"UTF8", input.getName());
			papidocJuricaSerializer = processor.newSerializer(outputSrcPapidoc);
//			debugOutput = new BufferedOutputStream(
//					new FileOutputStream(outputPapidocDirectory + "/../"
//						 + input.getName().replace(".xml", "-debug.xml")),
//					BUF_SIZE
//			);
//			debugSerializer = processor.newSerializer(debugOutput);

			XdmNode source = processor.newDocumentBuilder().build(new StreamSource(input));

			XsltTransformer lowercaseTrans = buildTransformer(input, lowercaseXslt);
			lowercaseTrans.setInitialContextNode(source);

			XsltTransformer injectCdcollTrans = buildTransformer(input, injectCdcollXslt);
			lowercaseTrans.setDestination(injectCdcollTrans);

			XsltTransformer filterNotIndexedTrans = buildTransformer(input, filterNotIndexedXslt);
			injectCdcollTrans.setDestination(filterNotIndexedTrans);

			XsltTransformer injectConfigDallozTrans =
					buildTransformer(input, injectConfigDallozXslt);
			filterNotIndexedTrans.setDestination(injectConfigDallozTrans);

			XsltTransformer genMetaFileTrans = buildTransformer(input, genMetaFileXslt);
			injectConfigDallozTrans.setDestination(genMetaFileTrans);

			XsltTransformer genUrTrans = buildTransformer(input, genUrXslt);
			genMetaFileTrans.setDestination(genUrTrans);

			XsltTransformer genEstSourceReproTrans = buildTransformer(input, genEstSourceReproXslt);
			genUrTrans.setDestination(genEstSourceReproTrans);

			XsltTransformer genSourceTrans = buildTransformer(input, genSourceXslt);
			genEstSourceReproTrans.setDestination(genSourceTrans);

			XsltTransformer normalizeTrans = buildTransformer(input, normalizeXslt);
			genSourceTrans.setDestination(normalizeTrans);

			XsltTransformer addMetaTrans = buildTransformer(input, addMetaXslt);
			normalizeTrans.setDestination(
//					new TeeDestination(
							addMetaTrans
//							, debugSerializer
//					)
			);

			XsltTransformer splitByUrTrans = buildTransformer(input, splitByUrXslt);
			addMetaTrans.setDestination(
//					new TeeDestination(
							splitByUrTrans
//							, debugSerializer
//					)
			);

			XsltTransformer filterUrTrans = buildTransformer(input, filterUrXslt);
			XsltTransformer mergeSourceBookTrans = buildTransformer(input, mergeSourceBookXslt);
			splitByUrTrans.setDestination(
//					new TeeDestination(
							new TeeDestination(filterUrTrans, mergeSourceBookTrans)
//							, debugSerializer
//					)
			);

			XsltTransformer filterJuricaTrans = buildTransformer(input, filterJuricaXslt);
			XsltTransformer filterNotJuricaTrans = buildTransformer(input, filterNotJuricaXslt);
			mergeSourceBookTrans.setDestination(
//					new TeeDestination(
							new TeeDestination(filterNotJuricaTrans, filterJuricaTrans)
//							, debugSerializer
//					)
			);

			XsltTransformer resolveTxtlrArticleTrans =
					buildTransformer(input, resolveTxtlrArticleXslt);
			filterNotJuricaTrans.setDestination(resolveTxtlrArticleTrans);
			resolveTxtlrArticleTrans.setDestination(databaseDestination);

			XsltTransformer filterSourceTransJurica = buildTransformer(input, filterSourceXslt);
			filterJuricaTrans.setDestination(
					new ComputeTriMeta4SourceDestination(filterSourceTransJurica, pdcs, sourceKeysByPdc,
							substitutionSet
					)
			);

			XsltTransformer genSearchMetaTrans = buildTransformer(input, genSearchMetaXslt);
			XsltTransformer genSearchMetaTransJurica = buildTransformer(input, genSearchMetaXslt);
			filterUrTrans.setDestination(
//					new TeeDestination(
							genSearchMetaTrans
//							, debugSerializer
//					)
			);
			filterSourceTransJurica.setDestination(genSearchMetaTransJurica);

			XsltTransformer unduplicateTitreSourceByIdSourceCommenteeTrans =
					buildTransformer(input, unduplicateTitreSourceByIdSourceCommenteeXslt);
			genSearchMetaTrans.setDestination(unduplicateTitreSourceByIdSourceCommenteeTrans);

			XsltTransformer outputPapidocTrans = buildTransformer(input, outputPapidocXslt);
			XsltTransformer outputPapidocTransJurica = buildTransformer(input, outputPapidocXslt);
			unduplicateTitreSourceByIdSourceCommenteeTrans.setDestination(outputPapidocTrans);
			outputPapidocTrans.setDestination(papidocSerializer);
			genSearchMetaTransJurica.setDestination(outputPapidocTransJurica);
			outputPapidocTransJurica.setDestination(papidocJuricaSerializer);

			lowercaseTrans.transform();

		} catch (Exception e) {
			throw new PipelineException(e.getMessage(), e);
		} finally {
			closeQuietlySerializer(papidocSerializer);
			IOUtils.closeQuietly(outputPapidoc);
			IOUtils.closeQuietly(outputSrcPapidoc);
//			IOUtils.closeQuietly(debugOutput);
		}

		return input;
	}
}
