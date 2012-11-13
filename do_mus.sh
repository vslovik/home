#! /bin/bash

ROOT_FOLDER=/home/lera/Downloads

# Read keyword
echo
echo -n "Enter keyword: "
read KEY
echo You typed: "$KEY"
NUMBER=`ls -1  $ROOT_FOLDER | grep $KEY | wc -l`
if [ $NUMBER -eq 0 ]
then
	echo "No album found"
	exit 1
fi
echo "Albums number to work out is $NUMBER" 
while :
do
	clear
	echo "Choose the mode which best fits you"
	for (( i=1 ; i <= $NUMBER ; i++ ))
	do
		ALBUM_NAME=`ls -1 $ROOT_FOLDER | grep $KEY | head -$i | tail -1`
		echo "$i. $ALBUM_NAME"
	done
	echo -n "Please enter option [1 - $NUMBER]"
	read opt
	if [ $opt -gt $NUMBER ]
        then
		opt=1
	fi
	ALBUM_NAME=`ls -1 $ROOT_FOLDER | grep $KEY | head -$opt | tail -1`
 	echo $ALBUM_NAME
	num_flacs=`ls -1 -R "$ROOT_FOLDER/$ALBUM_NAME" | grep ".flac" | grep -v .part | wc -l`
	num_apes=`ls -1 -R "$ROOT_FOLDER/$ALBUM_NAME" | grep ".ape" | grep -v .part | wc -l`
	num_cues=`ls -1 -R "$ROOT_FOLDER/$ALBUM_NAME" | grep ".cue" | grep -v .part | wc -l`
	if [ $num_flacs -gt 0 ]
	then
		suffix="flac"
		num=$num_flacs
	fi
	if [ $num_apes -gt 0 ]
        then
                suffix="ape"
                num=$num_apes
        fi
	if [ $num -gt 0 ]
	then	
		for (( k=1 ; k <= $num ; k++ ))
        	do
			file=`find "$ROOT_FOLDER/$ALBUM_NAME" -name *.$suffix | head -$k | tail -1`
			echo ".$suffix file:";
			echo  $file
			to_encode_file=`basename "$file"`
			dir=`dirname "$file"`
			wav_file=` echo $to_encode_file | sed "s/[-']//g" | sed 's/[ .]/_/g' | sed "s/.$suffix/.wav/"`
			prefix=`echo $wav_file | sed 's/.wav/_/'`
			wav_file="$dir/$wav_file"
			num_chunked=`ls -1 | grep "$prefix" | wc -l`
			num_wavs=`ls -1 | grep $prefix | grep ".wav" | wc -l`
			num_oggs=`ls -1 | grep $prefix | grep ".ogg" | wc -l`
			echo $prefix
			if [ ! -d $prefix ]
			then
                        	if [ ! -f "$wav_file" ] && [ $num_chunked -eq 0 ] && [ $num_oggs -eq 0 ]
				then
                                	echo "starts to decode $to_encode_file"
                                	ffmpeg -i "$file" "$wav_file" > /dev/null 2>&1 
                        	fi

				if [ -f "$wav_file" ] && [ $num_cues -gt 0 ] && [ $num_chunked -eq 0 ]
        	                then
					cue_file=`find "$ROOT_FOLDER/$ALBUM_NAME" -name *.cue | head -$k | tail -1`
					echo "cue file: $cue_file"
                        		if [ -f "$cue_file" ];
                        		then
						echo "starts to chunk"
                                        	bchunk -w "$wav_file" "$cue_file" $prefix
						rm "$wav_file"
					else
						echo "$cue_file not found"
                        		fi
				fi
				# encoding
				num_wavs=`ls -1 | grep $prefix | grep ".wav" | wc -l`
                        	if [ $num_wavs -gt 0 ] && [ $num_oggs -eq 0 ]
                        	then
                                	for (( k=1 ; k <= $num_wavs ; k++ ))
                                	do
                                        	w_file=`ls -1 | grep $prefix | grep ".wav" | head -$k | tail -1`
                                        	echo $w_file
                                        	oggenc $w_file -b320 > /dev/null 2>&1
                                        	rm $w_file
                                	done
                        	fi
				num_oggs=`ls -1 | grep $prefix | grep ".ogg" | wc -l`
                        	if [ $num_oggs -gt 0 ]
                        	then
                                	if [ ! -d $prefix ]
                                	then
                                        	mkdir $prefix
                                	fi
                                	if [ -d $prefix ]
                                	then
                                        	mv *.ogg $prefix
                                	fi
                        	fi
			fi
		done
	else
		echo "No file to decode"
	fi
	exit 1
done

