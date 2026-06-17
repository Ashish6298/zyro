function selectFormats(formats, requestedFormatId, mode) {
  const selectedFormat = formats.find(f => f.formatId === requestedFormatId);
  if (!selectedFormat) {
    throw new Error(`Requested format ID ${requestedFormatId} is not available.`);
  }

  if (mode === 'audio') {
    return { videoFormat: null, audioFormat: selectedFormat };
  }

  if (selectedFormat.isProgressive) {
    return { videoFormat: selectedFormat, audioFormat: null };
  }

  if (selectedFormat.hasVideo && !selectedFormat.hasAudio) {
    const audioFormats = formats.filter(f => f.hasAudio && !f.hasVideo);
    if (audioFormats.length === 0) {
      const progressiveFormats = formats.filter(f => f.isProgressive);
      if (progressiveFormats.length === 0) {
        throw new Error('No compatible audio streams found for merging.');
      }
      progressiveFormats.sort((a, b) => (b.bitrate || 0) - (a.bitrate || 0));
      return { videoFormat: selectedFormat, audioFormat: progressiveFormats[0] };
    }

    // Sort audio formats by quality (bitrate)
    audioFormats.sort((a, b) => (b.bitrate || 0) - (a.bitrate || 0));
    return { videoFormat: selectedFormat, audioFormat: audioFormats[0] };
  }

  if (selectedFormat.hasAudio && !selectedFormat.hasVideo) {
    return { videoFormat: null, audioFormat: selectedFormat };
  }

  throw new Error('Invalid format stream configuration.');
}

module.exports = { selectFormats };
